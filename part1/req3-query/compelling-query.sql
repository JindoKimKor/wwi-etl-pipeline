-- ============================================================
-- Req 3: Compelling Warehouse Queries — "Predict the Future"
-- Group 11 | PROG3240 Winter 2026
-- ============================================================
-- Run against: WWI_DM database (after Req 7 loads data)
-- Each query starts from FactSales and JOINs the Dims needed
-- ============================================================

USE WWI_DM;
GO

-- ============================================================
-- Query 1: Supplier Performance by City
-- ============================================================
-- Business scenario:
--   The company wants to optimize supplier contracts by region.
--   If Supplier A's products sell 3x more in a city than Supplier B's,
--   we should increase Supplier A's stock in that region.
--
-- What this query answers:
--   "Which supplier's products generate the most revenue in each city?"
--   → answerable because FactSales has both SupplierKey and LocationKey
--
-- Without Star Schema (3NF):
--   Orders + OrderLines + StockItems + Suppliers + Customers + Cities + ...
--   → 8+ table JOINs just to connect supplier to city
--
-- With Star Schema:
--   FactSales + DimSuppliers + DimLocation → done
--
-- Predict the Future:
--   If Supplier X dominates City Y → negotiate better terms with that supplier for that region
--   If a supplier is weak in a region → consider replacing with a stronger alternative
-- ============================================================

SELECT
    l.CityName,
    l.StateProvCode,
    s.FullName AS SupplierName,
    s.SupplierCategoryName,
    SUM(f.Quantity) AS TotalQuantity,
    SUM(f.TotalAfterTax) AS TotalRevenue,
    COUNT(*) AS NumberOfOrders
FROM dbo.FactSales f
JOIN dbo.DimLocation l     ON f.LocationKey = l.LocationKey
JOIN dbo.DimSuppliers s    ON f.SupplierKey = s.SupplierKey
JOIN dbo.DimCustomers c    ON f.CustomerKey = c.CustomerKey
JOIN dbo.DimProducts p     ON f.ProductKey  = p.ProductKey
JOIN dbo.DimSalesPeople sp ON f.SalespersonKey = sp.SalespersonKey
JOIN dbo.DimDate d         ON f.DateKey     = d.DateKey
GROUP BY l.CityName, l.StateProvCode, s.FullName, s.SupplierCategoryName
ORDER BY TotalRevenue DESC;
GO

-- ============================================================
-- Query 2: Salesperson × Supplier Performance
-- ============================================================
-- Business scenario:
--   Which salesperson sells which supplier's products best?
--   By matching salespeople to the suppliers they're most effective with,
--   we can optimize assignments and improve revenue.
--
-- What this query answers:
--   "For each salesperson, which supplier generates the most revenue?"
--   → answerable because FactSales has both SalespersonKey and SupplierKey
--
-- Predict the Future:
--   Salesperson X generates 80% from Supplier A → assign more of that supplier's accounts
--   Salesperson Y is weak with a key supplier → provide training or reassign
--   New supplier onboarded? → assign the salesperson best with similar categories
-- ============================================================

SELECT
    sp.FullName AS SalespersonName,
    s.FullName AS SupplierName,
    s.SupplierCategoryName,
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
ORDER BY TotalRevenue DESC;
GO

-- ============================================================
-- Query 3: Salesperson Efficiency by Customer Category
-- ============================================================
-- Business scenario:
--   Not all salespeople perform equally across customer types.
--   A salesperson who excels with Corporate clients might struggle with Novelty Shops.
--   We want to find the best match between salesperson and customer segment.
--
-- What this query answers:
--   "Which salesperson generates the most revenue per customer in each category?"
--   → answerable because FactSales has SalespersonKey and CustomerKey (→ category)
--
-- Without Star Schema (3NF):
--   Orders + Customers + CustomerCategories + People + ...
--   → need to figure out which People are salespeople, then join to categories
--
-- With Star Schema:
--   FactSales + DimSalesPeople + DimCustomers → done
--
-- Predict the Future:
--   Salesperson X has highest revenue/customer for "Corporate" → assign more Corporate accounts
--   Salesperson Y is inefficient with "Novelty Shop" → reassign or provide training
--   New customer segment growing? → assign the salesperson who performs best in similar segments
-- ============================================================

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
ORDER BY RevenuePerCustomer DESC;
