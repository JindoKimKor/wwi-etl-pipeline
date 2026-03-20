# Phase 0: Environment Setup

> **BI Concept:** None — pure environment setup
> **When complete:** `USE WideWorldImporters; SELECT TOP 5 * FROM Sales.Orders;` works in SSMS, and an empty WWI_DM DB exists

## Prerequisites

| Tool | Purpose |
|------|---------|
| SQL Server (local) | DB engine |
| SSMS | DB management |
| Visual Studio + SSIS Extension | SSIS package development (Part 2) |
| Python + pyodbc | Python ETL scripts (Part 2) |

## Restore WideWorldImporters

1. Download `.bak` file
   - [GitHub: sql-server-samples](https://github.com/microsoft/sql-server-samples/tree/master/samples/databases/wide-world-importers)
   - [Microsoft Docs](https://learn.microsoft.com/en-us/sql/samples/wide-world-importers-what-is?view=sql-server-ver17)
2. SSMS → Right-click Databases → **Restore Database...**
3. Device → `...` → Add → Select `.bak` file → OK
4. Verify:
   ```sql
   USE WideWorldImporters;
   SELECT COUNT(*) FROM Sales.Orders;
   -- Result: 73,595 rows (expected)
   ```

## Create WWI_DM

```sql
CREATE DATABASE WWI_DM;
GO
```

> Detailed script: [`setup.sql`](setup.sql)

## Checklist

- [ ] DROP existing WWI_DM DB if present
- [ ] Download WideWorldImporters `.bak` file
- [ ] Restore Database in SSMS → WideWorldImporters
- [ ] Verify: `USE WideWorldImporters; SELECT COUNT(*) FROM Sales.Orders;`
- [ ] Create WWI_DM DB: `CREATE DATABASE WWI_DM;`
- [ ] Review class note SQL (existing CREATE TABLE code from Week 7/9/10 PDFs)
