# Req 7: Execute & Verify (2 marks)

> **BI/Data Pipeline Concepts: End-to-End Pipeline Execution**
> - In production, this ETL runs automatically every day (Airflow, SSIS Agent Job, etc.)
> - Running 4 days sequentially = Proof that "this pipeline can run daily without issues"
> - Re-running Req 3 queries = Proof that "the pipeline's end consumer (analyst) can actually derive value"

## Expected Output

```sql
SELECT COUNT(*) FROM FactSales;
-- → Order data from 4 days is loaded

-- Run Req 3 queries → Business insight results with actual data
```

**This is the final completed state of Assignment 3.**

## PDF Requirements

- Execute 4 days of Orders ETL: **2013-01-01 ~ 2013-01-04**
- Re-run Req 3 queries → Verify results

## Execution Script

```sql
-- =============================================
-- Sequential ETL execution for 4 days
-- For each date: Extract → Transform → Load
-- =============================================

DECLARE @Date DATE = '2013-01-01';
DECLARE @EndDate DATE = '2013-01-04';

WHILE @Date <= @EndDate
BEGIN
    PRINT '===== Processing: ' + CAST(@Date AS VARCHAR) + ' =====';

    -- Extract
    EXEC dbo.Extract_Customers;
    EXEC dbo.Extract_Products;
    EXEC dbo.Extract_Salespeople;
    EXEC dbo.Extract_Orders @OrderDate = @Date;
    EXEC dbo.Extract_Suppliers;

    -- Transform
    EXEC dbo.Transform_DimCustomers;
    EXEC dbo.Transform_DimProducts;
    EXEC dbo.Transform_DimSalesPeople;
    EXEC dbo.Transform_DimLocation;
    EXEC dbo.Transform_DimSuppliers;
    EXEC dbo.Transform_FactSales;

    -- Load
    EXEC dbo.Load_DimCustomers;
    EXEC dbo.Load_DimProducts;
    EXEC dbo.Load_DimSalesPeople;
    EXEC dbo.Load_DimLocation;
    EXEC dbo.Load_DimSuppliers;
    EXEC dbo.Load_FactSales;

    SET @Date = DATEADD(DAY, 1, @Date);
END;

-- Verification
SELECT COUNT(*) AS FactSalesRows FROM dbo.FactSales;
SELECT COUNT(*) AS DimCustomerRows FROM dbo.DimCustomers;
SELECT COUNT(*) AS DimSupplierRows FROM dbo.DimSuppliers;
```

> **Note:** SP names may vary based on actual implementation. The above is an example structure.

## Integration Checklist

- [ ] Part1.sql: Execute in order Req 1 → 2 → 3 without errors
- [ ] Part2.sql: Stage CREATE → Extract SP → PreLoad CREATE → Transform SP → Load SP → Req 7 order
- [ ] Part2.py: Can run independently (connection string, table names match)
- [ ] Part2.dtsx: Can run independently (Connection Manager configured)
- [ ] **Run everything end-to-end from scratch on WideWorldImporters + empty WWI_DM without errors**

> PDF: "your professor will only be running it all in 1 Script / from the TOP & will not be able to analyse/diagnose/fix any of your SQL errors"

## Tasks

- [ ] Execute 4 days of ETL (2013-01-01 ~ 2013-01-04)
- [ ] Re-run Req 3 queries → Verify data is returned
- [ ] Full script integration execution test
