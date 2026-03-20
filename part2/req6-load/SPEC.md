# Req 6: ETL Loads (4 marks)

> **BI/Data Pipeline Concepts: The "L" in ETL — Loading + Transaction Safety**
> - **Load** = INSERT/UPDATE the finalized data from PreLoad into the final Dim/Fact tables
> - **Transaction (BEGIN TRAN / COMMIT / ROLLBACK)** = "All succeed or all cancel" principle
>   - What if an error occurs at the 3000th customer out of 5000? → Prevents an incomplete state with only 3000 loaded
>   - Roll back everything to maintain a clean state
> - **Load order matters:** Dims first → Facts after (because Facts reference Dim Keys as FKs)

## Expected Output

```sql
SELECT COUNT(*) FROM DimCustomers;  -- → Customer data exists
SELECT COUNT(*) FROM FactSales;     -- → Order data exists
-- All FKs are validly connected
```

## PDF Requirements

- SP to load changed records into Dimension tables
- SP to load data into Fact table
- **On partial failure, ROLLBACK remaining updates for that table** (best practices)

## Load SP Pattern

### Dimension Load (with Transaction)

```sql
CREATE OR ALTER PROCEDURE dbo.Load_DimCustomers
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        -- MERGE or INSERT/UPDATE from PreLoad
        MERGE dbo.DimCustomers AS target
        USING dbo.PreLoad_DimCustomers AS source
        ON target.CustomerKey = source.CustomerKey
        WHEN MATCHED THEN
            UPDATE SET target.CustomerName = source.CustomerName, ...
        WHEN NOT MATCHED THEN
            INSERT (CustomerKey, CustomerName, ...)
            VALUES (source.CustomerKey, source.CustomerName, ...);

        COMMIT TRANSACTION;
        PRINT 'DimCustomers load successful.';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT 'DimCustomers load FAILED. Transaction rolled back.';
        THROW;
    END CATCH
END;
GO
```

### Fact Load

```sql
CREATE OR ALTER PROCEDURE dbo.Load_FactSales
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO dbo.FactSales (CustomerKey, LocationKey, ProductKey, ...)
        SELECT CustomerKey, LocationKey, ProductKey, ...
        FROM dbo.PreLoad_FactSales;

        COMMIT TRANSACTION;
        PRINT 'FactSales load successful.';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT 'FactSales load FAILED. Transaction rolled back.';
        THROW;
    END CATCH
END;
GO
```

### Load Execution Order

```sql
-- 1. Dimensions first (FK reference targets)
EXEC dbo.Load_DimCustomers;
EXEC dbo.Load_DimProducts;
EXEC dbo.Load_DimSalesPeople;
EXEC dbo.Load_DimLocation;
EXEC dbo.Load_DimSuppliers;

-- 2. Facts after (FK referencing side)
EXEC dbo.Load_FactSales;
```

## Tasks

- [ ] Load SP: DimCustomers (with Transaction)
- [ ] Load SP: DimProducts
- [ ] Load SP: DimSalesPeople
- [ ] Load SP: DimLocation
- [ ] Load SP: DimSuppliers (SCD2 — includes expired records)
- [ ] Load SP: FactSales
- [ ] Test ROLLBACK on failure

## References

- **Week 10 PDF:** `resources/course-material/PROG3240_week10_etl-using-t-sql-and-ssis.pdf`
  - Load SP patterns, Transaction handling, MERGE syntax
