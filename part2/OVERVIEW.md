# Part 2: ETL Pipeline (20 marks)

Build the full ETL pipeline: WideWorldImporters → Stage → PreLoad → WWI_DM (Dim/Fact).

## Requirements Overview

| Req                   | Description                                    | Marks | Owner     | SPEC                        |
| --------------------- | ---------------------------------------------- | ----- | --------- | --------------------------- |
| [Req 4](req4-extract/)   | Extract — T-SQL (A) + Python (B) + SSIS (C)   | 6     | A + B + C | [SPEC](req4-extract/SPEC.md)   |
| [Req 5](req5-transform/) | Transform — T-SQL (A) + Python (B) + SSIS (C) | 8     | A + B + C | [SPEC](req5-transform/SPEC.md) |
| [Req 6](req6-load/)      | Load — Dim/Fact Load SP + Transaction         | 4     | Member A  | [SPEC](req6-load/SPEC.md)      |
| [Req 7](req7-execute/)   | Run ETL for 2013-01-01~04 + Req 3 query        | 2     | Member A  | [SPEC](req7-execute/SPEC.md)   |

## Full ETL Flow

```
WideWorldImporters (3NF)           WWI_DM (Star Schema)
┌──────────────────┐               ┌──────────────────┐
│ Sales.Orders     │               │                  │
│ Sales.Customers  │  ┌─────────┐  │ DimCustomers     │
│ Warehouse.Stock  │→ │  Stage  │  │ DimProducts      │
│ Purchasing.Supp  │  │ Tables  │  │ DimSalesPeople   │
│ Application.Peo  │  └────┬────┘  │ DimLocation      │
│ Application.Cit  │       ↓       │ DimDate          │
└──────────────────┘  ┌─────────┐  │ DimSuppliers     │
                      │ PreLoad │  │ FactSales        │
                      │ Tables  │→ │                  │
                      └─────────┘  └──────────────────┘

                  Extract    Transform    Load
                  (Req 4)    (Req 5)     (Req 6)
```

## Prerequisites

- Phase 0 complete: SQL Server Enterprise Developer installed, WideWorldImporters restored, WWI_DM database created
- Part 1 complete: All Dim/Fact tables created (Req 1), DimDate populated (Req 2)
- See [Part 1 OVERVIEW](../part1/OVERVIEW.md)

## Dependencies

```
Req 1 (Tables) → Req 4 (Extract)
                    └→ Req 5 (Transform)
                          └→ Req 6 (Load)
                                └→ Req 7 (Execute 4 days + Req 3 query)
```

## Member Distribution

| Member      | Req 4 (Extract) | Req 5 (Transform) |
| ----------- | --------------- | ----------------- |
| **A** | T-SQL (all SPs) | T-SQL (all SPs)   |
| **B** | Python (min 1)  | Python (min 1)    |
| **C** | SSIS (min 1)    | SSIS (min 1)      |

Req 6, 7 = T-SQL only (Member A).

## Course Materials

- **Week 9 PDF:** SCD Type 1 & 2 Concepts
- **Week 10 PDF:** T-SQL ETL Full Pattern (Extract → Transform → Load) + SSIS setup
- **Lab 6:** Python ↔ SQL Server Connection (pyodbc)

## Deliverables

- `Part2_Group11.sql` — All ETL Stored Procedures (Req 4 + 5 + 6 + 7)
- `Part2_Group11.py` — Python: Req 4 Extract + Req 5 Transform (Member B)
- `Part2_Group11.dtsx` — SSIS: Req 4 Extract + Req 5 Transform (Member C)
