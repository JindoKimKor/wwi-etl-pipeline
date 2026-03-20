# Part 2: ETL Pipeline (20 marks)

Build the full ETL pipeline: WideWorldImporters → Stage → PreLoad → WWI_DM (Dim/Fact).

## Requirements Overview

| Req | Description | Marks | Owner |
|-----|-------------|-------|-------|
| [Req 4](req4-extract/) | Extract — Stage Tables + SP + Python + SSIS | 6 | Member B |
| [Req 5](req5-transform/) | Transform — PreLoad + SCD1/SCD2 + Python + SSIS | 8 | Member C |
| [Req 6](req6-load/) | Load — Dim/Fact Load SP + Transaction | 4 | Member A |
| [Req 7](req7-execute/) | Execute — Run 4 days + Validation Queries | 2 | Member A |

## Full ETL Flow

```
WideWorldImporters (OLTP)          WWI_DM (Star Schema)
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

## Dependencies

```
Req 1 (Tables) → Req 4 (Extract)
                    └→ Req 5 (Transform)
                          └→ Req 6 (Load)
                                └→ Req 7 (Execute 4 days)
```

## Python / SSIS Requirements

| Tool | Req 4 (Extract) | Req 5 (Transform) | Total |
|------|-----------------|-------------------|-------|
| **Python** | At least 1 | At least 1 | **At least 1 (4 or 5)** |
| **SSIS** | At least 1 | At least 1 | **At least 1 (4 or 5)** |

> PDF: "at least 1 python and 1 SSIS package" — 1 each required in Req 4 and 5

## Course Materials

- **Week 9 PDF:** SCD Type 1 & 2 Concepts
  - `resources/course-material/PROG3240_week9_slowly-changing-dimension-and-etl.pdf`
- **Week 10 PDF:** T-SQL ETL Full Pattern (Extract → Transform → Load)
  - `resources/course-material/PROG3240_week10_etl-using-t-sql-and-ssis.pdf`
- **Lab 6:** Python ↔ SQL Server Connection (pyodbc)
  - `resources/labs/lab-6/MSSQL_Connect.ipynb`
  - `resources/labs/lab-6/lab-6-review.md`

## Reference Videos

- [Install SSIS in Visual Studio: Build Your First ETL Task](https://www.youtube.com/watch?v=oqG0g0W9EuU)
- [Create an ETL package with SSIS! // step-by-step](https://www.youtube.com/watch?v=msCJxaA63IA)
- [SCD Type 2 in SSIS Using Lookup](https://www.youtube.com/watch?v=7uj463csru0)
- [SQL ETL Tutorial for Beginners](https://www.youtube.com/watch?v=uy8-0rX-RV8)

## Deliverables

- `Part2_Group11.sql` — All ETL Stored Procedures
- `Part2_Group11.py` — Python Extract or Transform (at least 1)
- `Part2_Group11.dtsx` — SSIS Package (at least 1)

> **Note:** Exclude DimPickingStaff (PDF: "Exclude DimPickingStaff")
