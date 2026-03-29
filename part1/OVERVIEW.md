# Part 1: Star Schema (10 marks)

Build a Star Schema-based Data Warehouse + load date dimension + analytical query.

## Requirements Overview

| Req                 | Description                                  | Marks | Source                                               |
| ------------------- | -------------------------------------------- | ----- | ---------------------------------------------------- |
| [Req 1](req1-schema/)  | Dimensional Model tables (PKs, FKs, Indexes) | 5     | [create-tables.sql](req1-schema/create-tables.sql)      |
| [Req 2](req2-dimdate/) | DimDate_Load SP + WHILE Loop 5 years         | 3     | [dimdate-load.sql](req2-dimdate/dimdate-load.sql)       |
| [Req 3](req3-query/)   | Compelling Query — "Predict the Future"     | 2     | [compelling-query.sql](req3-query/compelling-query.sql) |

## Prerequisites

- Phase 0 complete: SQL Server Enterprise Developer installed, WideWorldImporters restored, WWI_DM database created
- See [SETUP-GUIDE](../part0-setup/SETUP-GUIDE.md)

## Dependencies

```
Phase 0 (Environment Setup)
  └→ Req 1 (Table creation) 
       └→ Req 2 (DimDate load)
            └→ Req 3 (Written now, tested after Req 7 loads data)
```

## Deliverable

[Part1_Group11.sql](../submission/Part1_Group11.sql) — Req 1 + 2 + 3 combined into a single file.

## Course Materials

- **Week 7 PDF:** Star Schema, FactOrders, DimDate, Indexes
- **Week 9 PDF:** SCD Types (p.6-18), DimCustomers/Products/SalesPeople/Location CREATE TABLE (p.18)
- **Exploration notebook:** [req1-schema/part-b-explore.ipynb](req1-schema/part-b-explore.ipynb)
