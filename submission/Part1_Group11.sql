-- ============================================================
-- Part 1: Star Schema Construction
-- Group 11 | PROG3240 Winter 2026
-- ============================================================
-- Run against: WWI_DM database
-- Source: WideWorldImporters (OLTP)
-- ============================================================

USE master;
GO

IF DB_ID('WWI_DM') IS NOT NULL
BEGIN
    ALTER DATABASE WWI_DM SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE WWI_DM;
END
GO

CREATE DATABASE WWI_DM;
GO

USE WWI_DM;
GO

/* REQUIREMENT 1 — Dimensional Model Tables (5 marks) */

-- ============================================================
-- DIMENSION TABLES
-- ============================================================

-- DimLocation (SCD Type 1)
-- Flattens: Cities → StateProvinces → Countries (3 tables → 1)
-- Type 1: city/country names rarely change, no history needed
CREATE TABLE dbo.DimLocation (
    LocationKey         INT             NOT NULL IDENTITY(1,1),
    CityName            NVARCHAR(50)    NULL,
    StateProvCode       NVARCHAR(5)     NULL,
    StateProvName       NVARCHAR(50)    NULL,
    CountryName         NVARCHAR(60)    NULL,
    CountryFormalName   NVARCHAR(60)    NULL,
    CONSTRAINT PK_DimLocation PRIMARY KEY (LocationKey)
);
GO

-- DimCustomers (SCD Type 2)
-- Flattens: Customers + CustomerCategories + Cities chain (8 tables → 1)
-- Type 2: if customer name/category changes, historical orders should keep the original values
-- Location columns are redundant with DimLocation but included per class design
CREATE TABLE dbo.DimCustomers (
    CustomerKey             INT             NOT NULL IDENTITY(1,1),
    CustomerName            NVARCHAR(100)   NULL,
    CustomerCategoryName    NVARCHAR(50)    NULL,
    DeliveryCityName        NVARCHAR(50)    NULL,
    DeliveryStateProvCode   NVARCHAR(5)     NULL,
    DeliveryCountryName     NVARCHAR(50)    NULL,
    PostalCityName          NVARCHAR(50)    NULL,
    PostalStateProvCode     NVARCHAR(5)     NULL,
    PostalCountryName       NVARCHAR(50)    NULL,
    StartDate               DATE            NOT NULL,
    EndDate                 DATE            NULL,
    CONSTRAINT PK_DimCustomers PRIMARY KEY (CustomerKey)
);
GO

-- DimProducts (SCD Type 2)
-- Flattens: StockItems + Colors (2 tables → 1)
-- Type 2: if product brand/colour changes, historical sales should reflect what was true at the time
-- Colour, Brand, Size are nullable — not all products have these attributes
CREATE TABLE dbo.DimProducts (
    ProductKey      INT             NOT NULL IDENTITY(1,1),
    ProductName     NVARCHAR(100)   NULL,
    ProductColour   NVARCHAR(20)    NULL,
    ProductBrand    NVARCHAR(50)    NULL,
    ProductSize     NVARCHAR(20)    NULL,
    StartDate       DATE            NOT NULL,
    EndDate         DATE            NULL,
    CONSTRAINT PK_DimProducts PRIMARY KEY (ProductKey)
);
GO

-- DimSalesPeople (SCD Type 1)
-- Source: People table filtered by IsSalesperson = 1
-- Type 1: different name = different person; contact info is unrelated to sales — just overwrite
CREATE TABLE dbo.DimSalesPeople (
    SalespersonKey  INT             NOT NULL IDENTITY(1,1),
    FullName        NVARCHAR(50)    NULL,
    PreferredName   NVARCHAR(50)    NULL,
    LogonName       NVARCHAR(50)    NULL,
    PhoneNumber     NVARCHAR(20)    NULL,
    FaxNumber       NVARCHAR(20)    NULL,
    EmailAddress    NVARCHAR(256)   NULL,
    CONSTRAINT PK_DimSalesPeople PRIMARY KEY (SalespersonKey)
);
GO

-- DimDate (SCD Type 0)
-- Calculated, no source table — dates are permanent facts
-- Smart Key: YYYYMMDD integer (e.g. 20130101) — always unique, never changes
-- All columns derivable from DateValue, pre-calculated for read performance
CREATE TABLE dbo.DimDate (
    DateKey         INT             NOT NULL,
    DateValue       DATE            NOT NULL,
    CYear           SMALLINT        NOT NULL,
    CMonth          TINYINT         NOT NULL,
    DayNo           TINYINT         NOT NULL,
    CQtr            TINYINT         NOT NULL,
    StartOfMonth    DATE            NOT NULL,
    EndOfMonth      DATE            NOT NULL,
    MonthName       VARCHAR(9)      NOT NULL,
    DayOfWeekName   VARCHAR(9)      NOT NULL,
    CONSTRAINT PK_DimDate PRIMARY KEY (DateKey)
);
GO

-- DimSuppliers (SCD Type 2)
-- Flattens: Suppliers + SupplierCategories (2 tables → 1)
-- Type 2: if supplier name/category changes, we need to know what it was at the time of each sale
-- Business key: FullName (same pattern as DimCustomers using CustomerName)
CREATE TABLE dbo.DimSuppliers (
    SupplierKey             INT             NOT NULL IDENTITY(1,1),
    FullName                NVARCHAR(100)   NULL,
    PhoneNumber             NVARCHAR(20)    NULL,
    FaxNumber               NVARCHAR(20)    NULL,
    WebsiteURL              NVARCHAR(256)   NULL,
    SupplierCategoryName    NVARCHAR(50)    NULL,
    StartDate               DATE            NOT NULL,
    EndDate                 DATE            NULL,
    CONSTRAINT PK_DimSuppliers PRIMARY KEY (SupplierKey)
);
GO

-- ============================================================
-- FACT TABLE
-- No PK, no surrogate key — users access facts through dimensions, not directly
-- Each FK connects to one dimension (one analysis axis)
-- ============================================================

CREATE TABLE dbo.FactSales (
    CustomerKey     INT             NOT NULL,
    LocationKey     INT             NOT NULL,
    ProductKey      INT             NOT NULL,
    SalespersonKey  INT             NOT NULL,
    SupplierKey     INT             NOT NULL,
    DateKey         INT             NOT NULL,
    Quantity        INT             NOT NULL,
    UnitPrice       DECIMAL(18,2)   NOT NULL,
    TaxRate         DECIMAL(18,3)   NOT NULL,
    TotalBeforeTax  DECIMAL(18,2)   NOT NULL,
    TotalAfterTax   DECIMAL(18,2)   NOT NULL,

    CONSTRAINT FK_FactSales_DimCustomers
        FOREIGN KEY (CustomerKey)   REFERENCES dbo.DimCustomers(CustomerKey),
    CONSTRAINT FK_FactSales_DimLocation
        FOREIGN KEY (LocationKey)   REFERENCES dbo.DimLocation(LocationKey),
    CONSTRAINT FK_FactSales_DimProducts
        FOREIGN KEY (ProductKey)    REFERENCES dbo.DimProducts(ProductKey),
    CONSTRAINT FK_FactSales_DimSalesPeople
        FOREIGN KEY (SalespersonKey) REFERENCES dbo.DimSalesPeople(SalespersonKey),
    CONSTRAINT FK_FactSales_DimSuppliers
        FOREIGN KEY (SupplierKey)   REFERENCES dbo.DimSuppliers(SupplierKey),
    CONSTRAINT FK_FactSales_DimDate
        FOREIGN KEY (DateKey)       REFERENCES dbo.DimDate(DateKey)
);
GO

-- ============================================================
-- INDEXES
-- One non-clustered index per FK
-- Users search dimensions first, then seek matching facts
-- ============================================================

CREATE INDEX IX_FactSales_CustomerKey    ON dbo.FactSales (CustomerKey);
CREATE INDEX IX_FactSales_LocationKey    ON dbo.FactSales (LocationKey);
CREATE INDEX IX_FactSales_ProductKey     ON dbo.FactSales (ProductKey);
CREATE INDEX IX_FactSales_SalespersonKey ON dbo.FactSales (SalespersonKey);
CREATE INDEX IX_FactSales_SupplierKey    ON dbo.FactSales (SupplierKey);
CREATE INDEX IX_FactSales_DateKey        ON dbo.FactSales (DateKey);
GO

/* REQUIREMENT 2 — DimDate Stored Procedure + Load (3 marks) */

-- ============================================================
-- DimDate_Load Stored Procedure
-- Input: one date → calculates all DimDate columns
-- DateKey = YYYYMMDD Smart Key (not IDENTITY)
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.DimDate_Load
    @DateValue DATE
AS
BEGIN
    INSERT INTO dbo.DimDate
    SELECT
        CAST(YEAR(@DateValue) * 10000 + MONTH(@DateValue) * 100 + DAY(@DateValue) AS INT),
        @DateValue,
        YEAR(@DateValue),
        MONTH(@DateValue),
        DAY(@DateValue),
        DATEPART(qq, @DateValue),
        DATEADD(DAY, 1, EOMONTH(@DateValue, -1)),
        EOMONTH(@DateValue),
        DATENAME(mm, @DateValue),
        DATENAME(dw, @DateValue);
END;
GO

-- ============================================================
-- Load 5 years: 2012-01-01 to 2016-12-31
-- DimDate must be populated before FactSales loads (FK dependency)
-- WideWorldImporters data spans 2013-2016, 2012 = buffer year
-- ============================================================

DECLARE @StartDate DATE = '2012-01-01';
DECLARE @EndDate   DATE = '2016-12-31';
DECLARE @Date      DATE = @StartDate;

WHILE @Date <= @EndDate
BEGIN
    EXEC dbo.DimDate_Load @DateValue = @Date;
    SET @Date = DATEADD(DAY, 1, @Date);
END;
GO

/* REQUIREMENT 3 — Compelling Warehouse Queries (2 marks) */

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
