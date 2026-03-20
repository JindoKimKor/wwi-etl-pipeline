# Req 5: Transform (8 marks)

## Contract: PreLoad Table Structure (this Req defines → Req 6 consumes)

The PreLoad tables created in this Req become the **input for Req 6 (Load)**. Member A needs to know the column names/types of the PreLoad tables to write Load SPs.

| PreLoad Table | Consumer | Structure |
|---------------|----------|-----------|
| PreLoad_DimCustomers | Load_DimCustomers | Same structure as DimCustomers (includes Surrogate Key) |
| PreLoad_DimProducts | Load_DimProducts | Same structure as DimProducts |
| PreLoad_DimSalesPeople | Load_DimSalesPeople | Same structure as DimSalesPeople |
| PreLoad_DimLocation | Load_DimLocation | Same structure as DimLocation |
| PreLoad_DimSuppliers | Load_DimSuppliers | Same structure as DimSuppliers (SCD2: EffectiveDate, EndDate, IsCurrent) |
| PreLoad_FactSales | Load_FactSales | Same structure as FactSales (FKs converted to Surrogate Keys) |

> **Input Contract (received from Req 4):** Stage_* tables → see [req4 SPEC](../req4-extract/SPEC.md)
> **Output Contract (passed to Req 6):** PreLoad_* tables → Finalize and share this structure before starting Req 6.

---

> **BI/Data Pipeline Concepts: The "T" in ETL — Transformation + Slowly Changing Dimensions**
> - **SCD Type 1 (Overwrite):** What if a customer's phone number changes? → Simply UPDATE to the latest value. Previous value is not kept
> - **SCD Type 2 (History Preservation):** What if supplier info changes? → "Expire" the previous record and add a new one. Why? Enables point-in-time analysis like "What were the sales when this supplier was at address A last year?"
> - **Surrogate Key** = An artificial key auto-generated in the DW (1,2,3...). Mapped to the source's Business Key (e.g., customer number)
> - **PreLoad Table** = An intermediate table that holds Transform results. Stage (source form) → PreLoad (DW form) → Dim (final)

## Expected Output

```sql
SELECT * FROM PreLoad_DimSuppliers;
-- → Supplier data from Stage is transformed into DW form
-- → SupplierKey assigned, SCD2 columns EffectiveDate/EndDate/IsCurrent set

-- SCD2 test: Modify supplier info then run Transform again
-- → Same supplier exists as 2 rows (previous version + current version)
```

## PDF Requirements

### SCD Type 1 Dimensions (4)

| Dim | Method | Core Logic |
|-----|--------|------------|
| DimCustomers | SCD Type 1 | Assign new key via Sequence, update if existing |
| DimProducts | SCD Type 1 | Same pattern |
| DimSalesPeople | SCD Type 1 | Same pattern |
| DimLocation | SCD Type 1 | Same pattern |

**Sequence Usage:**
```sql
CREATE SEQUENCE dbo.Seq_DimCustomers START WITH 1 INCREMENT BY 1;

-- New record → NEXT VALUE FOR dbo.Seq_DimCustomers
-- Existing record → Keep existing surrogate key
```

### SCD Type 2 Dimension (DimSuppliers) — Key Requirement!

**4 Cases:**

| Case | Condition | Action |
|------|-----------|--------|
| a. Match, no change | Stage ∩ DW, attributes identical | Keep as-is (add to PreLoad unchanged) |
| b. Match, changed | Stage ∩ DW, non-key attributes changed | **Add new record + expire existing record** |
| c. New record | Exists in Stage but not in DW | **Create new record** |
| d. Missing record | Exists in DW but not in Stage | **Expire existing record** |

```sql
-- Expire = Set EndDate + IsCurrent = 0
UPDATE DimSuppliers
SET EndDate = GETDATE(), IsCurrent = 0
WHERE SupplierBusinessKey = @Key AND IsCurrent = 1;
```

### FactSales Transform

- Look up Surrogate Keys using Business Keys from Stage_Orders data
- INSERT into PreLoad_FactSales using the Surrogate Keys
- Same measure aggregation approach as in class notes

### Validation

- Handle error if Stage tables are empty (RAISERROR or PRINT)

## SSIS Transform Guide

1. Data Flow Task → **Lookup** component for Surrogate Key mapping
2. **Conditional Split** to branch on Match/No Match
3. **OLE DB Command** for UPDATE (expiration handling)
4. **OLE DB Destination** for new record INSERT

## Tasks

- [ ] CREATE TABLE for PreLoad tables (same structure as each Dim)
- [ ] Create Sequences (for each SCD Type 1 Dim)
- [ ] Transform SP: Customers (SCD1)
- [ ] Transform SP: Products (SCD1)
- [ ] Transform SP: Salespeople (SCD1)
- [ ] Transform SP: Location (SCD1)
- [ ] Transform SP: Suppliers (SCD2 — 4 cases)
- [ ] Transform SP: Orders/Facts (surrogate key lookup + aggregation)
- [ ] Convert 1 to Python
- [ ] Convert 1 to SSIS package
- [ ] Empty record validation error handling

## References

- **Week 9 PDF:** `resources/course-material/PROG3240_week9_slowly-changing-dimension-and-etl.pdf`
  - SCD Type 1/2 concepts, case explanations
- **Week 10 PDF:** `resources/course-material/PROG3240_week10_etl-using-t-sql-and-ssis.pdf`
  - Transform SP patterns, PreLoad table structure, Sequence usage
- **Video:** [SCD Type 2 in SSIS Using Lookup](https://www.youtube.com/watch?v=7uj463csru0)
- **Lab 6:** `resources/labs/lab-6/MSSQL_Connect.ipynb` — Reference for Python implementation
