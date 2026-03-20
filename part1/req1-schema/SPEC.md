# Req 1: Dimensional Model Tables (5 marks)

## Contract: Dim/Fact Structure (This Req defines → everyone consumes)

The table structure defined in this Req serves as **the foundation for Req 2, 4, 5, and 6**. If column names/types change, the entire downstream is affected, so **this structure must be finalized first and shared with the team**.

| Table | Consumer |
|--------|--------|
| DimCustomers, DimProducts, DimSalesPeople, DimLocation, DimDate | Req 4 (Extract), Req 5 (Transform), Req 6 (Load) |
| DimSuppliers (SCD2) | Req 5 (Transform — SCD2 logic), Req 6 (Load) |
| FactSales + all FK/Index | Req 5 (Transform — surrogate key lookup), Req 6 (Load) |

---

> **BI Concepts: Star Schema (Dimensional Modelling)**
> - **Fact Table** = Central table containing measures (numbers). "How much was sold?" (Quantity, UnitPrice, TotalAfterTax)
> - **Dimension Table** = Context that describes the Fact. "Who? What? Where? When? Supplied by whom?"
> - **Star Schema** = Structure where 1 Fact + multiple Dims are connected by FKs (star shape)
> - **Surrogate Key** = Artificial key for DW only (1,2,3...). Separate from the source DB's Business Key
> - **SCD Type 2** = When data changes, "expire" the existing record and add a new record (preserves history)

## Expected Output

- In SSMS, `SELECT * FROM WWI_DM.dbo.DimSuppliers` → Empty table but column structure is visible
- In Database Diagram, Star Schema visualization with 7 Dims connected in a star shape around FactSales

## PDF Requirements

- Add **DimSuppliers** to the existing Star Schema SQL from class notes
- DimSuppliers uses **SCD Type 2** (preserves history when non-key attributes change)
- Add `SupplierKey` FK to FactSales
- Create **Index** for each FK
- Verify unique/business key from `Purchasing.Suppliers` table (refer to DimCustomers pattern)

## Already created in class (class notes SQL)

```sql
-- DimCustomers (customer dimension)
-- DimProducts (product dimension)
-- DimSalesPeople (salesperson dimension)
-- DimLocation/DimCities (city dimension)
-- DimDate (date dimension)
-- FactSales (sales fact)
-- Indexes (index for each FK)
```

### Existing Index Pattern (class SQL)

```sql
CREATE INDEX IX_FactOrders_CustomerKey    ON dbo.FactOrders (CustomerKey);
CREATE INDEX IX_FactOrders_CityKey        ON dbo.FactOrders (CityKey);
CREATE INDEX IX_FactOrders_ProductKey     ON dbo.FactOrders (ProductKey);
CREATE INDEX IX_FactOrders_SalespersonKey ON dbo.FactOrders (SalespersonKey);
CREATE INDEX IX_FactOrders_DateKey        ON dbo.FactOrders (DateKey);
```

## New additions: DimSuppliers

### Star Schema Diagram (per PDF)

```
DimSuppliers: SupplierKey, FullName, PhoneNumber, FaxNumber, WebsiteURL
DimDate:      DateKey, DateValue, Month, Day, Quarter, StartOfMonth, EndOfMonth, MonthName, DayOfWeekName
DimProducts:  (existing)
DimSalesPeople: (existing)
DimCustomers: (existing)
DimLocation:  (existing)

FactSales: CustomerKey, LocationKey, ProductKey, SalespersonKey, SupplierKey(NEW), DateKey,
           Quantity, UnitPrice, TaxRate, TotalBeforeTax, TotalAfterTax
```

### DimSuppliers Design Guide

**Source table:** `WideWorldImporters.Purchasing.Suppliers`

```sql
-- Verify source
SELECT TOP 5 * FROM WideWorldImporters.Purchasing.Suppliers;
SELECT TOP 5 * FROM WideWorldImporters.Purchasing.SupplierCategories;
```

**Including SCD Type 2 columns:**

```sql
CREATE TABLE dbo.DimSuppliers (
    SupplierKey       INT           NOT NULL IDENTITY(1,1),  -- Surrogate Key
    -- Business Key (brought from source)
    -- ... (decide after reviewing Purchasing.Suppliers structure)
    FullName          NVARCHAR(100) NOT NULL,
    PhoneNumber       NVARCHAR(20)  NOT NULL,
    FaxNumber         NVARCHAR(20)  NOT NULL,
    WebsiteURL        NVARCHAR(256) NOT NULL,
    -- SCD Type 2 columns
    EffectiveDate     DATETIME2     NOT NULL DEFAULT GETDATE(),
    EndDate           DATETIME2     NULL,
    IsCurrent         BIT           NOT NULL DEFAULT 1,
    CONSTRAINT PK_DimSuppliers PRIMARY KEY (SupplierKey)
);
```

**FactSales update:**

```sql
ALTER TABLE dbo.FactSales ADD SupplierKey INT NOT NULL;
ALTER TABLE dbo.FactSales ADD CONSTRAINT FK_FactSales_DimSuppliers
    FOREIGN KEY (SupplierKey) REFERENCES dbo.DimSuppliers(SupplierKey);
CREATE INDEX IX_FactSales_SupplierKey ON dbo.FactSales (SupplierKey);
```

## Tasks

- [ ] Copy & run class SQL code (create existing Dim + Fact tables)
- [ ] Verify `WideWorldImporters.Purchasing.Suppliers` table structure (source)
- [ ] Write DimSuppliers CREATE TABLE (SCD Type 2 → include EffectiveDate, EndDate, IsCurrent)
- [ ] Add SupplierKey column + FK + Index to FactSales
- [ ] Run all & verify

## References

- **Week 7 PDF:** `resources/course-material/PROG3240_week7_dimensional-model-part1.pdf`
  - Star Schema structure, CREATE TABLE code, Index patterns
- **Logbook:** `logbook/2026-02-26/log.md`
  - SQL code written during class (Raw section)
- **Assignment PDF:** `docs/assignment-3-instruction.pdf` (Page 2 — Star Schema diagram)

### Note: Adding SupplierCategoryName

> PDF: "Business Analyst and SME review of the Supplier source tables suggests that SupplierCategory might also influence sales orders, so please add the SupplierCategoryName field to the appropriate table in the dimensional model."

→ Must add `SupplierCategoryName` column to DimSuppliers!
