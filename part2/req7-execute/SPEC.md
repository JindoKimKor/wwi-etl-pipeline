# Req 7: Execute & Verify (2 marks)

> Run the full ETL pipeline for 4 days, then execute Req 3 queries to verify.

---

## What are we doing?

Req 4 (Extract), 5 (Transform), 6 (Load) created all the SPs.
Now we **run them** — simulating 4 days of real ETL operation.

In production, ETL runs automatically every day. Here we simulate that by running it 4 times manually, once per day.

## Execution (2013-01-01 ~ 2013-01-04)

For each date:
```
Extract (pull from WideWorldImporters for that date)
  → Transform (convert to Star Schema format)
    → Load (insert into final Dim/Fact tables)
```

```sql
-- For each day: full ETL cycle
DECLARE @Date DATE = '2013-01-01';
DECLARE @EndDate DATE = '2013-01-04';

WHILE @Date <= @EndDate
BEGIN
    PRINT '===== Processing: ' + CAST(@Date AS VARCHAR) + ' =====';

    -- Extract
    EXEC dbo.Customers_Extract;
    EXEC dbo.Products_Extract;
    EXEC dbo.SalesPeople_Extract;
    EXEC dbo.Orders_Extract @OrderDate = @Date;
    EXEC dbo.Suppliers_Extract;

    -- Transform
    EXEC dbo.Location_Transform;
    EXEC dbo.Customers_Transform;
    EXEC dbo.Products_Transform;
    EXEC dbo.SalesPeople_Transform;
    EXEC dbo.Suppliers_Transform;
    EXEC dbo.Orders_Transform;

    -- Load (Dims first, then Fact)
    EXEC dbo.Location_Load;
    EXEC dbo.Customers_Load;
    EXEC dbo.Products_Load;
    EXEC dbo.SalesPeople_Load;
    EXEC dbo.Suppliers_Load;
    EXEC dbo.Orders_Load;

    SET @Date = DATEADD(DAY, 1, @Date);
END;
```

Note: SP names may vary based on actual implementation.

## Verify

After 4 days of ETL:

```sql
-- Data exists in all tables?
SELECT COUNT(*) AS FactSalesRows FROM dbo.FactSales;
SELECT COUNT(*) AS DimCustomerRows FROM dbo.DimCustomers;
SELECT COUNT(*) AS DimSupplierRows FROM dbo.DimSuppliers;
SELECT COUNT(*) AS DimDateRows FROM dbo.DimDate;
```

Then run **Req 3 queries** — they should now return actual data:
- Query 1: Supplier performance by city → revenue numbers
- Query 2: Brand trends over time → daily/monthly data
- Query 3: Salesperson efficiency → revenue per customer

## Why 4 days?

- Day 1: all records are new (first load)
- Day 2-4: tests that SCD logic works correctly
  - Type 1: existing records get overwritten
  - Type 2: if any attributes changed, new records created + old expired
  - Fact: new rows added each day

4 days is enough to prove the pipeline handles both initial load and incremental updates.
