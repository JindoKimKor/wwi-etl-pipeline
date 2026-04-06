-- ============================================================
-- Req 7: Execute ETL for 4 days + run Req 3 queries
-- Group 11 | PROG3240 Winter 2026
-- ============================================================
-- Runs full ETL cycle (Extract → Transform → Load) for each day
-- Then re-runs the Req 3 compelling queries to verify data
-- ============================================================

USE WWI_DM;
GO

-- ============================================================
-- Execute 4 days: 2013-01-01 to 2013-01-04
-- ============================================================

DECLARE @Date DATE = '2013-01-01';
DECLARE @EndDate DATE = '2013-01-04';

WHILE @Date <= @EndDate
BEGIN
    PRINT '===== Processing: ' + CAST(@Date AS VARCHAR) + ' =====';

    -- Extract (Stage tables)
    EXEC dbo.Customers_Extract;
    EXEC dbo.Products_Extract;
    EXEC dbo.SalesPeople_Extract;
    EXEC dbo.Suppliers_Extract;
    EXEC dbo.Orders_Extract @OrderDate = @Date;

    -- Transform (PreLoad tables)
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
GO

-- ============================================================
-- Verify: data loaded?
-- ============================================================

SELECT COUNT(*) AS FactSalesRows FROM dbo.FactSales;
SELECT COUNT(*) AS DimCustomerRows FROM dbo.DimCustomers;
SELECT COUNT(*) AS DimProductRows FROM dbo.DimProducts;
SELECT COUNT(*) AS DimSupplierRows FROM dbo.DimSuppliers;
SELECT COUNT(*) AS DimLocationRows FROM dbo.DimLocation;
SELECT COUNT(*) AS DimSalesPeopleRows FROM dbo.DimSalesPeople;
GO

-- ============================================================
-- Re-run Req 3 queries — should now return actual data
-- ============================================================

-- Query 1: Supplier Performance by City (CTE + ranking)
WITH CitySupplier AS (
    SELECT
        l.CityName, l.StateProvCode,
        s.FullName AS SupplierName, s.SupplierCategoryName,
        COUNT(DISTINCT p.ProductKey) AS Products,
        SUM(f.Quantity) AS TotalQuantity,
        SUM(f.TotalAfterTax) AS TotalRevenue
    FROM dbo.FactSales f
    JOIN dbo.DimLocation l     ON f.LocationKey    = l.LocationKey
    JOIN dbo.DimSuppliers s    ON f.SupplierKey    = s.SupplierKey
    JOIN dbo.DimCustomers c    ON f.CustomerKey    = c.CustomerKey
    JOIN dbo.DimProducts p     ON f.ProductKey     = p.ProductKey
    JOIN dbo.DimSalesPeople sp ON f.SalespersonKey = sp.SalespersonKey
    JOIN dbo.DimDate d         ON f.DateKey        = d.DateKey
    GROUP BY l.CityName, l.StateProvCode, s.FullName, s.SupplierCategoryName
),
CityTotal AS (
    SELECT CityName, SUM(TotalRevenue) AS CityRevenue FROM CitySupplier GROUP BY CityName
)
SELECT
    cs.CityName, cs.StateProvCode,
    cs.SupplierName, cs.SupplierCategoryName,
    cs.Products, cs.TotalQuantity, cs.TotalRevenue,
    CAST(cs.TotalRevenue * 100.0 / ct.CityRevenue AS DECIMAL(5,1)) AS RevenueSharePct,
    RANK() OVER (PARTITION BY cs.CityName ORDER BY cs.TotalRevenue DESC) AS SupplierRankInCity
FROM CitySupplier cs
JOIN CityTotal ct ON cs.CityName = ct.CityName
ORDER BY ct.CityRevenue DESC, cs.TotalRevenue DESC;
GO

-- Query 2: Salesperson × Supplier Performance (CTE + ranking)
WITH SalespersonSupplier AS (
    SELECT
        sp.FullName AS SalespersonName,
        s.FullName AS SupplierName, s.SupplierCategoryName,
        COUNT(DISTINCT p.ProductKey) AS Products,
        SUM(f.Quantity) AS TotalQuantity,
        SUM(f.TotalAfterTax) AS TotalRevenue
    FROM dbo.FactSales f
    JOIN dbo.DimSalesPeople sp ON f.SalespersonKey = sp.SalespersonKey
    JOIN dbo.DimSuppliers s    ON f.SupplierKey    = s.SupplierKey
    JOIN dbo.DimProducts p     ON f.ProductKey     = p.ProductKey
    JOIN dbo.DimCustomers c    ON f.CustomerKey    = c.CustomerKey
    JOIN dbo.DimLocation l     ON f.LocationKey    = l.LocationKey
    JOIN dbo.DimDate d         ON f.DateKey        = d.DateKey
    GROUP BY sp.FullName, s.FullName, s.SupplierCategoryName
),
SalespersonTotal AS (
    SELECT SalespersonName, SUM(TotalRevenue) AS SalespersonRevenue
    FROM SalespersonSupplier GROUP BY SalespersonName
)
SELECT
    ss.SalespersonName, ss.SupplierName, ss.SupplierCategoryName,
    ss.Products, ss.TotalQuantity, ss.TotalRevenue,
    CAST(ss.TotalRevenue * 100.0 / st.SalespersonRevenue AS DECIMAL(5,1)) AS RevenueSharePct,
    RANK() OVER (PARTITION BY ss.SalespersonName ORDER BY ss.TotalRevenue DESC) AS SupplierRankPerSalesperson
FROM SalespersonSupplier ss
JOIN SalespersonTotal st ON ss.SalespersonName = st.SalespersonName
ORDER BY st.SalespersonRevenue DESC, ss.TotalRevenue DESC;
GO

-- Query 3: Salesperson Efficiency by Customer Category (CTE + ranking)
WITH SalespersonCategory AS (
    SELECT
        sp.FullName AS SalespersonName,
        c.CustomerCategoryName,
        COUNT(DISTINCT c.CustomerKey) AS UniqueCustomers,
        SUM(f.Quantity) AS TotalQuantity,
        SUM(f.TotalAfterTax) AS TotalRevenue,
        SUM(f.TotalAfterTax) / COUNT(DISTINCT c.CustomerKey) AS RevenuePerCustomer
    FROM dbo.FactSales f
    JOIN dbo.DimSalesPeople sp ON f.SalespersonKey = sp.SalespersonKey
    JOIN dbo.DimCustomers c    ON f.CustomerKey    = c.CustomerKey
    JOIN dbo.DimProducts p     ON f.ProductKey     = p.ProductKey
    JOIN dbo.DimLocation l     ON f.LocationKey    = l.LocationKey
    JOIN dbo.DimSuppliers s    ON f.SupplierKey    = s.SupplierKey
    JOIN dbo.DimDate d         ON f.DateKey        = d.DateKey
    GROUP BY sp.FullName, c.CustomerCategoryName
),
CategoryTotal AS (
    SELECT CustomerCategoryName, SUM(TotalRevenue) AS CategoryRevenue
    FROM SalespersonCategory GROUP BY CustomerCategoryName
)
SELECT
    sc.CustomerCategoryName, sc.SalespersonName,
    sc.UniqueCustomers, sc.TotalQuantity, sc.TotalRevenue,
    sc.RevenuePerCustomer,
    CAST(sc.TotalRevenue * 100.0 / ct.CategoryRevenue AS DECIMAL(5,1)) AS RevenueSharePct,
    RANK() OVER (PARTITION BY sc.CustomerCategoryName ORDER BY sc.TotalRevenue DESC) AS SalespersonRankInCategory
FROM SalespersonCategory sc
JOIN CategoryTotal ct ON sc.CustomerCategoryName = ct.CustomerCategoryName
ORDER BY ct.CategoryRevenue DESC, sc.TotalRevenue DESC;
GO
