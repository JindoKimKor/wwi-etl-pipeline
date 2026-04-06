-- ============================================================
-- Part 2: ETL Pipeline
-- Group 11 | PROG3240 Winter 2026
-- ============================================================
-- Run against: WWI_DM database (after Part1_Group11.sql)
-- Source: WideWorldImporters (OLTP)
-- ============================================================

USE WWI_DM;
GO

/* REQUIREMENT 4 - Extract (6 marks) */

-- ============================================================
-- STAGE TABLES (flat, no PK, no constraints)
-- ============================================================

DROP TABLE IF EXISTS dbo.Customers_Stage;
DROP TABLE IF EXISTS dbo.Products_Stage;
DROP TABLE IF EXISTS dbo.SalesPeople_Stage;
DROP TABLE IF EXISTS dbo.Suppliers_Stage;
DROP TABLE IF EXISTS dbo.Orders_Stage;
GO

CREATE TABLE dbo.Customers_Stage (
    CustomerName                NVARCHAR(100)   NULL,
    CustomerCategoryName        NVARCHAR(50)    NULL,
    DeliveryCityName            NVARCHAR(50)    NULL,
    DeliveryStateProvCode       NVARCHAR(5)     NULL,
    DeliveryStateProvName       NVARCHAR(50)    NULL,
    DeliveryCountryName         NVARCHAR(50)    NULL,
    DeliveryCountryFormalName   NVARCHAR(50)    NULL,
    PostalCityName              NVARCHAR(50)    NULL,
    PostalStateProvCode         NVARCHAR(5)     NULL,
    PostalStateProvName         NVARCHAR(50)    NULL,
    PostalCountryName           NVARCHAR(50)    NULL,
    PostalCountryFormalName     NVARCHAR(50)    NULL
);
GO

CREATE TABLE dbo.Products_Stage (
    ProductName     NVARCHAR(100)   NULL,
    ProductColour   NVARCHAR(20)    NULL,
    ProductBrand    NVARCHAR(50)    NULL,
    ProductSize     NVARCHAR(20)    NULL
);
GO

CREATE TABLE dbo.SalesPeople_Stage (
    FullName        NVARCHAR(50)    NULL,
    PreferredName   NVARCHAR(50)    NULL,
    LogonName       NVARCHAR(50)    NULL,
    PhoneNumber     NVARCHAR(20)    NULL,
    FaxNumber       NVARCHAR(20)    NULL,
    EmailAddress    NVARCHAR(256)   NULL
);
GO

CREATE TABLE dbo.Suppliers_Stage (
    FullName                NVARCHAR(100)   NULL,
    PhoneNumber             NVARCHAR(20)    NULL,
    FaxNumber               NVARCHAR(20)    NULL,
    WebsiteURL              NVARCHAR(256)   NULL,
    SupplierCategoryName    NVARCHAR(50)    NULL
);
GO

CREATE TABLE dbo.Orders_Stage (
    OrderDate           DATE            NULL,
    Quantity            INT             NULL,
    UnitPrice           DECIMAL(18,2)   NULL,
    TaxRate             DECIMAL(18,3)   NULL,
    CustomerName        NVARCHAR(100)   NULL,
    CityName            NVARCHAR(50)    NULL,
    StateProvinceName   NVARCHAR(50)    NULL,
    CountryName         NVARCHAR(60)    NULL,
    StockItemName       NVARCHAR(100)   NULL,
    LogonName           NVARCHAR(50)    NULL,
    SupplierName        NVARCHAR(50)    NULL
);
GO

-- ============================================================
-- EXTRACT STORED PROCEDURES
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.Customers_Extract
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    TRUNCATE TABLE dbo.Customers_Stage;
    WITH CityDetails AS (
        SELECT ci.CityID, ci.CityName,
               sp.StateProvinceCode, sp.StateProvinceName,
               co.CountryName, co.FormalName
        FROM WideWorldImporters.Application.Cities ci
        LEFT JOIN WideWorldImporters.Application.StateProvinces sp
            ON ci.StateProvinceID = sp.StateProvinceID
        LEFT JOIN WideWorldImporters.Application.Countries co
            ON sp.CountryID = co.CountryID
    )
    INSERT INTO dbo.Customers_Stage
    SELECT cust.CustomerName, cat.CustomerCategoryName,
           dc.CityName, dc.StateProvinceCode, dc.StateProvinceName,
           dc.CountryName, dc.FormalName,
           pc.CityName, pc.StateProvinceCode, pc.StateProvinceName,
           pc.CountryName, pc.FormalName
    FROM WideWorldImporters.Sales.Customers cust
    LEFT JOIN WideWorldImporters.Sales.CustomerCategories cat
        ON cust.CustomerCategoryID = cat.CustomerCategoryID
    LEFT JOIN CityDetails dc ON cust.DeliveryCityID = dc.CityID
    LEFT JOIN CityDetails pc ON cust.PostalCityID = pc.CityID;
    DECLARE @RowCt INT = @@ROWCOUNT;
    IF @RowCt = 0 RAISERROR('Customers_Extract: no rows.', 16, 1);
    PRINT 'Customers_Extract: ' + CAST(@RowCt AS VARCHAR) + ' rows.';
END;
GO

CREATE OR ALTER PROCEDURE dbo.Products_Extract
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    TRUNCATE TABLE dbo.Products_Stage;
    INSERT INTO dbo.Products_Stage
    SELECT si.StockItemName, c.ColorName, si.Brand, si.Size
    FROM WideWorldImporters.Warehouse.StockItems si
    LEFT JOIN WideWorldImporters.Warehouse.Colors c ON si.ColorID = c.ColorID;
    DECLARE @RowCt INT = @@ROWCOUNT;
    IF @RowCt = 0 RAISERROR('Products_Extract: no rows.', 16, 1);
    PRINT 'Products_Extract: ' + CAST(@RowCt AS VARCHAR) + ' rows.';
END;
GO

CREATE OR ALTER PROCEDURE dbo.SalesPeople_Extract
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    TRUNCATE TABLE dbo.SalesPeople_Stage;
    INSERT INTO dbo.SalesPeople_Stage
    SELECT FullName, PreferredName, LogonName, PhoneNumber, FaxNumber, EmailAddress
    FROM WideWorldImporters.Application.People
    WHERE IsSalesperson = 1;
    DECLARE @RowCt INT = @@ROWCOUNT;
    IF @RowCt = 0 RAISERROR('SalesPeople_Extract: no rows.', 16, 1);
    PRINT 'SalesPeople_Extract: ' + CAST(@RowCt AS VARCHAR) + ' rows.';
END;
GO

CREATE OR ALTER PROCEDURE dbo.Suppliers_Extract
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    TRUNCATE TABLE dbo.Suppliers_Stage;
    INSERT INTO dbo.Suppliers_Stage
    SELECT s.SupplierName, s.PhoneNumber, s.FaxNumber, s.WebsiteURL, sc.SupplierCategoryName
    FROM WideWorldImporters.Purchasing.Suppliers s
    JOIN WideWorldImporters.Purchasing.SupplierCategories sc
        ON s.SupplierCategoryID = sc.SupplierCategoryID;
    DECLARE @RowCt INT = @@ROWCOUNT;
    IF @RowCt = 0 RAISERROR('Suppliers_Extract: no rows.', 16, 1);
    PRINT 'Suppliers_Extract: ' + CAST(@RowCt AS VARCHAR) + ' rows.';
END;
GO

CREATE OR ALTER PROCEDURE dbo.Orders_Extract
    @OrderDate DATE
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    TRUNCATE TABLE dbo.Orders_Stage;
    INSERT INTO dbo.Orders_Stage
    SELECT o.OrderDate, ol.Quantity, ol.UnitPrice, ol.TaxRate,
           c.CustomerName, ci.CityName, sp.StateProvinceName, co.CountryName,
           si.StockItemName, p.LogonName, sup.SupplierName
    FROM WideWorldImporters.Sales.Orders o
    JOIN WideWorldImporters.Sales.OrderLines ol ON o.OrderID = ol.OrderID
    JOIN WideWorldImporters.Sales.Customers c ON o.CustomerID = c.CustomerID
    JOIN WideWorldImporters.Application.Cities ci ON c.DeliveryCityID = ci.CityID
    JOIN WideWorldImporters.Application.StateProvinces sp ON ci.StateProvinceID = sp.StateProvinceID
    JOIN WideWorldImporters.Application.Countries co ON sp.CountryID = co.CountryID
    JOIN WideWorldImporters.Warehouse.StockItems si ON ol.StockItemID = si.StockItemID
    JOIN WideWorldImporters.Application.People p ON o.SalespersonPersonID = p.PersonID
    JOIN WideWorldImporters.Purchasing.Suppliers sup ON si.SupplierID = sup.SupplierID
    WHERE o.OrderDate = @OrderDate;
    DECLARE @RowCt INT = @@ROWCOUNT;
    IF @RowCt = 0 RAISERROR('Orders_Extract: no rows for this date.', 16, 1);
    PRINT 'Orders_Extract (' + CAST(@OrderDate AS VARCHAR) + '): ' + CAST(@RowCt AS VARCHAR) + ' rows.';
END;
GO

-- ============================================================
-- TEST EXTRACTS (as required by assignment)
-- "Test each of your Extract stored procedures by executing each one of them."
-- ============================================================

EXEC dbo.Customers_Extract;
EXEC dbo.Products_Extract;
EXEC dbo.SalesPeople_Extract;
EXEC dbo.Suppliers_Extract;
EXEC dbo.Orders_Extract @OrderDate = '2013-01-01';
GO

/* REQUIREMENT 5 - Transform (8 marks) */

-- ============================================================
-- PRELOAD TABLES (same structure as Dim/Fact, no FK)
-- ============================================================

DROP TABLE IF EXISTS dbo.Location_Preload;
DROP TABLE IF EXISTS dbo.Customers_Preload;
DROP TABLE IF EXISTS dbo.Products_Preload;
DROP TABLE IF EXISTS dbo.SalesPeople_Preload;
DROP TABLE IF EXISTS dbo.Suppliers_Preload;
DROP TABLE IF EXISTS dbo.Orders_Preload;
GO

CREATE TABLE dbo.Location_Preload (
    LocationKey INT NOT NULL, CityName NVARCHAR(50) NULL,
    StateProvCode NVARCHAR(5) NULL, StateProvName NVARCHAR(50) NULL,
    CountryName NVARCHAR(60) NULL, CountryFormalName NVARCHAR(60) NULL,
    CONSTRAINT PK_Location_Preload PRIMARY KEY CLUSTERED (LocationKey)
);
GO
CREATE TABLE dbo.Customers_Preload (
    CustomerKey INT NOT NULL, CustomerName NVARCHAR(100) NULL,
    CustomerCategoryName NVARCHAR(50) NULL,
    DeliveryCityName NVARCHAR(50) NULL, DeliveryStateProvCode NVARCHAR(5) NULL,
    DeliveryCountryName NVARCHAR(50) NULL,
    PostalCityName NVARCHAR(50) NULL, PostalStateProvCode NVARCHAR(5) NULL,
    PostalCountryName NVARCHAR(50) NULL,
    StartDate DATE NOT NULL, EndDate DATE NULL,
    CONSTRAINT PK_Customers_Preload PRIMARY KEY CLUSTERED (CustomerKey)
);
GO
CREATE TABLE dbo.Products_Preload (
    ProductKey INT NOT NULL, ProductName NVARCHAR(100) NULL,
    ProductColour NVARCHAR(20) NULL, ProductBrand NVARCHAR(50) NULL,
    ProductSize NVARCHAR(20) NULL, StartDate DATE NOT NULL, EndDate DATE NULL,
    CONSTRAINT PK_Products_Preload PRIMARY KEY CLUSTERED (ProductKey)
);
GO
CREATE TABLE dbo.SalesPeople_Preload (
    SalespersonKey INT NOT NULL, FullName NVARCHAR(50) NULL,
    PreferredName NVARCHAR(50) NULL, LogonName NVARCHAR(50) NULL,
    PhoneNumber NVARCHAR(20) NULL, FaxNumber NVARCHAR(20) NULL,
    EmailAddress NVARCHAR(256) NULL,
    CONSTRAINT PK_SalesPeople_Preload PRIMARY KEY CLUSTERED (SalespersonKey)
);
GO
CREATE TABLE dbo.Suppliers_Preload (
    SupplierKey INT NOT NULL, FullName NVARCHAR(100) NULL,
    PhoneNumber NVARCHAR(20) NULL, FaxNumber NVARCHAR(20) NULL,
    WebsiteURL NVARCHAR(256) NULL, SupplierCategoryName NVARCHAR(50) NULL,
    StartDate DATE NOT NULL, EndDate DATE NULL,
    CONSTRAINT PK_Suppliers_Preload PRIMARY KEY CLUSTERED (SupplierKey)
);
GO
CREATE TABLE dbo.Orders_Preload (
    CustomerKey INT NOT NULL, LocationKey INT NOT NULL,
    ProductKey INT NOT NULL, SalespersonKey INT NOT NULL,
    SupplierKey INT NOT NULL, DateKey INT NOT NULL,
    Quantity INT NOT NULL, UnitPrice DECIMAL(18,2) NOT NULL,
    TaxRate DECIMAL(18,3) NOT NULL, TotalBeforeTax DECIMAL(18,2) NOT NULL,
    TotalAfterTax DECIMAL(18,2) NOT NULL
);
GO

-- ============================================================
-- SEQUENCES
-- ============================================================

IF NOT EXISTS (SELECT * FROM sys.sequences WHERE name = 'LocationKey')
    CREATE SEQUENCE dbo.LocationKey START WITH 1;
GO
IF NOT EXISTS (SELECT * FROM sys.sequences WHERE name = 'CustomerKey')
    CREATE SEQUENCE dbo.CustomerKey START WITH 1;
GO
IF NOT EXISTS (SELECT * FROM sys.sequences WHERE name = 'ProductKey')
    CREATE SEQUENCE dbo.ProductKey START WITH 1;
GO
IF NOT EXISTS (SELECT * FROM sys.sequences WHERE name = 'SalespersonKey')
    CREATE SEQUENCE dbo.SalespersonKey START WITH 1;
GO
IF NOT EXISTS (SELECT * FROM sys.sequences WHERE name = 'SupplierKey')
    CREATE SEQUENCE dbo.SupplierKey START WITH 1;
GO

-- ============================================================
-- TRANSFORM STORED PROCEDURES
-- ============================================================

-- Location_Transform (SCD Type 1)
CREATE OR ALTER PROCEDURE dbo.Location_Transform
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.Customers_Stage)
        RAISERROR('Location_Transform: Customers_Stage is empty.', 16, 1);
    TRUNCATE TABLE dbo.Location_Preload;

    INSERT INTO dbo.Location_Preload
    SELECT NEXT VALUE FOR dbo.LocationKey,
           cu.DeliveryCityName, cu.DeliveryStateProvCode, cu.DeliveryStateProvName,
           cu.DeliveryCountryName, cu.DeliveryCountryFormalName
    FROM dbo.Customers_Stage cu
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.DimLocation loc
        WHERE cu.DeliveryCityName = loc.CityName
          AND cu.DeliveryStateProvName = loc.StateProvName
          AND cu.DeliveryCountryName = loc.CountryName
    )
    GROUP BY cu.DeliveryCityName, cu.DeliveryStateProvCode,
             cu.DeliveryStateProvName, cu.DeliveryCountryName, cu.DeliveryCountryFormalName;

    INSERT INTO dbo.Location_Preload
    SELECT loc.LocationKey,
           cu.DeliveryCityName, cu.DeliveryStateProvCode, cu.DeliveryStateProvName,
           cu.DeliveryCountryName, cu.DeliveryCountryFormalName
    FROM dbo.Customers_Stage cu
    JOIN dbo.DimLocation loc
        ON cu.DeliveryCityName = loc.CityName
       AND cu.DeliveryStateProvName = loc.StateProvName
       AND cu.DeliveryCountryName = loc.CountryName
    GROUP BY loc.LocationKey, cu.DeliveryCityName, cu.DeliveryStateProvCode,
             cu.DeliveryStateProvName, cu.DeliveryCountryName, cu.DeliveryCountryFormalName;

    PRINT 'Location_Transform: done.';
END;
GO

-- SalesPeople_Transform (SCD Type 1)
CREATE OR ALTER PROCEDURE dbo.SalesPeople_Transform
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.SalesPeople_Stage)
        RAISERROR('SalesPeople_Transform: SalesPeople_Stage is empty.', 16, 1);
    TRUNCATE TABLE dbo.SalesPeople_Preload;

    INSERT INTO dbo.SalesPeople_Preload
    SELECT NEXT VALUE FOR dbo.SalespersonKey,
           stg.FullName, stg.PreferredName, stg.LogonName,
           stg.PhoneNumber, stg.FaxNumber, stg.EmailAddress
    FROM dbo.SalesPeople_Stage stg
    WHERE NOT EXISTS (SELECT 1 FROM dbo.DimSalesPeople sp WHERE stg.LogonName = sp.LogonName);

    INSERT INTO dbo.SalesPeople_Preload
    SELECT sp.SalespersonKey,
           stg.FullName, stg.PreferredName, stg.LogonName,
           stg.PhoneNumber, stg.FaxNumber, stg.EmailAddress
    FROM dbo.SalesPeople_Stage stg
    JOIN dbo.DimSalesPeople sp ON stg.LogonName = sp.LogonName;

    PRINT 'SalesPeople_Transform: done.';
END;
GO

-- Customers_Transform (SCD Type 2)
CREATE OR ALTER PROCEDURE dbo.Customers_Transform
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.Customers_Stage)
        RAISERROR('Customers_Transform: Customers_Stage is empty.', 16, 1);
    TRUNCATE TABLE dbo.Customers_Preload;
    DECLARE @StartDate DATE = GETDATE();
    DECLARE @EndDate DATE = DATEADD(dd, -1, GETDATE());

    -- Case b: changed → new record
    INSERT INTO dbo.Customers_Preload
    SELECT NEXT VALUE FOR dbo.CustomerKey,
           stg.CustomerName, stg.CustomerCategoryName,
           stg.DeliveryCityName, stg.DeliveryStateProvCode, stg.DeliveryCountryName,
           stg.PostalCityName, stg.PostalStateProvCode, stg.PostalCountryName,
           @StartDate, NULL
    FROM dbo.Customers_Stage stg
    JOIN dbo.DimCustomers cu ON stg.CustomerName = cu.CustomerName AND cu.EndDate IS NULL
    WHERE stg.CustomerCategoryName <> cu.CustomerCategoryName
       OR stg.DeliveryCityName <> cu.DeliveryCityName
       OR stg.DeliveryStateProvCode <> cu.DeliveryStateProvCode
       OR stg.DeliveryCountryName <> cu.DeliveryCountryName
       OR stg.PostalCityName <> cu.PostalCityName
       OR stg.PostalStateProvCode <> cu.PostalStateProvCode
       OR stg.PostalCountryName <> cu.PostalCountryName;

    -- Case a + expire old from case b
    INSERT INTO dbo.Customers_Preload
    SELECT cu.CustomerKey, cu.CustomerName, cu.CustomerCategoryName,
           cu.DeliveryCityName, cu.DeliveryStateProvCode, cu.DeliveryCountryName,
           cu.PostalCityName, cu.PostalStateProvCode, cu.PostalCountryName,
           cu.StartDate,
           CASE WHEN EXISTS (
               SELECT 1 FROM dbo.Customers_Stage stg
               WHERE stg.CustomerName = cu.CustomerName
                 AND (stg.CustomerCategoryName <> cu.CustomerCategoryName
                   OR stg.DeliveryCityName <> cu.DeliveryCityName
                   OR stg.DeliveryStateProvCode <> cu.DeliveryStateProvCode
                   OR stg.DeliveryCountryName <> cu.DeliveryCountryName
                   OR stg.PostalCityName <> cu.PostalCityName
                   OR stg.PostalStateProvCode <> cu.PostalStateProvCode
                   OR stg.PostalCountryName <> cu.PostalCountryName)
           ) THEN @EndDate ELSE cu.EndDate END
    FROM dbo.DimCustomers cu
    WHERE cu.EndDate IS NULL
      AND EXISTS (SELECT 1 FROM dbo.Customers_Stage stg WHERE stg.CustomerName = cu.CustomerName);

    -- Case c: new
    INSERT INTO dbo.Customers_Preload
    SELECT NEXT VALUE FOR dbo.CustomerKey,
           stg.CustomerName, stg.CustomerCategoryName,
           stg.DeliveryCityName, stg.DeliveryStateProvCode, stg.DeliveryCountryName,
           stg.PostalCityName, stg.PostalStateProvCode, stg.PostalCountryName,
           @StartDate, NULL
    FROM dbo.Customers_Stage stg
    WHERE NOT EXISTS (SELECT 1 FROM dbo.DimCustomers cu WHERE stg.CustomerName = cu.CustomerName);

    -- Case d: expire missing
    INSERT INTO dbo.Customers_Preload
    SELECT cu.CustomerKey, cu.CustomerName, cu.CustomerCategoryName,
           cu.DeliveryCityName, cu.DeliveryStateProvCode, cu.DeliveryCountryName,
           cu.PostalCityName, cu.PostalStateProvCode, cu.PostalCountryName,
           cu.StartDate, @EndDate
    FROM dbo.DimCustomers cu
    WHERE cu.EndDate IS NULL
      AND NOT EXISTS (SELECT 1 FROM dbo.Customers_Stage stg WHERE stg.CustomerName = cu.CustomerName);

    PRINT 'Customers_Transform: done.';
END;
GO

-- Products_Transform (SCD Type 2)
CREATE OR ALTER PROCEDURE dbo.Products_Transform
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.Products_Stage)
        RAISERROR('Products_Transform: Products_Stage is empty.', 16, 1);
    TRUNCATE TABLE dbo.Products_Preload;
    DECLARE @StartDate DATE = GETDATE();
    DECLARE @EndDate DATE = DATEADD(dd, -1, GETDATE());

    INSERT INTO dbo.Products_Preload
    SELECT NEXT VALUE FOR dbo.ProductKey,
           stg.ProductName, stg.ProductColour, stg.ProductBrand, stg.ProductSize,
           @StartDate, NULL
    FROM dbo.Products_Stage stg
    JOIN dbo.DimProducts pr ON stg.ProductName = pr.ProductName AND pr.EndDate IS NULL
    WHERE ISNULL(stg.ProductColour,'') <> ISNULL(pr.ProductColour,'')
       OR ISNULL(stg.ProductBrand,'') <> ISNULL(pr.ProductBrand,'')
       OR ISNULL(stg.ProductSize,'') <> ISNULL(pr.ProductSize,'');

    INSERT INTO dbo.Products_Preload
    SELECT pr.ProductKey, pr.ProductName, pr.ProductColour, pr.ProductBrand, pr.ProductSize,
           pr.StartDate,
           CASE WHEN EXISTS (
               SELECT 1 FROM dbo.Products_Stage stg
               WHERE stg.ProductName = pr.ProductName
                 AND (ISNULL(stg.ProductColour,'') <> ISNULL(pr.ProductColour,'')
                   OR ISNULL(stg.ProductBrand,'') <> ISNULL(pr.ProductBrand,'')
                   OR ISNULL(stg.ProductSize,'') <> ISNULL(pr.ProductSize,''))
           ) THEN @EndDate ELSE pr.EndDate END
    FROM dbo.DimProducts pr
    WHERE pr.EndDate IS NULL
      AND EXISTS (SELECT 1 FROM dbo.Products_Stage stg WHERE stg.ProductName = pr.ProductName);

    INSERT INTO dbo.Products_Preload
    SELECT NEXT VALUE FOR dbo.ProductKey,
           stg.ProductName, stg.ProductColour, stg.ProductBrand, stg.ProductSize,
           @StartDate, NULL
    FROM dbo.Products_Stage stg
    WHERE NOT EXISTS (SELECT 1 FROM dbo.DimProducts pr WHERE stg.ProductName = pr.ProductName);

    INSERT INTO dbo.Products_Preload
    SELECT pr.ProductKey, pr.ProductName, pr.ProductColour, pr.ProductBrand, pr.ProductSize,
           pr.StartDate, @EndDate
    FROM dbo.DimProducts pr
    WHERE pr.EndDate IS NULL
      AND NOT EXISTS (SELECT 1 FROM dbo.Products_Stage stg WHERE stg.ProductName = pr.ProductName);

    PRINT 'Products_Transform: done.';
END;
GO

-- Suppliers_Transform (SCD Type 2)
CREATE OR ALTER PROCEDURE dbo.Suppliers_Transform
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.Suppliers_Stage)
        RAISERROR('Suppliers_Transform: Suppliers_Stage is empty.', 16, 1);
    TRUNCATE TABLE dbo.Suppliers_Preload;
    DECLARE @StartDate DATE = GETDATE();
    DECLARE @EndDate DATE = DATEADD(dd, -1, GETDATE());

    INSERT INTO dbo.Suppliers_Preload
    SELECT NEXT VALUE FOR dbo.SupplierKey,
           stg.FullName, stg.PhoneNumber, stg.FaxNumber, stg.WebsiteURL, stg.SupplierCategoryName,
           @StartDate, NULL
    FROM dbo.Suppliers_Stage stg
    JOIN dbo.DimSuppliers su ON stg.FullName = su.FullName AND su.EndDate IS NULL
    WHERE stg.PhoneNumber <> su.PhoneNumber OR stg.FaxNumber <> su.FaxNumber
       OR stg.WebsiteURL <> su.WebsiteURL OR stg.SupplierCategoryName <> su.SupplierCategoryName;

    INSERT INTO dbo.Suppliers_Preload
    SELECT su.SupplierKey, su.FullName, su.PhoneNumber, su.FaxNumber,
           su.WebsiteURL, su.SupplierCategoryName, su.StartDate,
           CASE WHEN EXISTS (
               SELECT 1 FROM dbo.Suppliers_Stage stg
               WHERE stg.FullName = su.FullName
                 AND (stg.PhoneNumber <> su.PhoneNumber OR stg.FaxNumber <> su.FaxNumber
                   OR stg.WebsiteURL <> su.WebsiteURL OR stg.SupplierCategoryName <> su.SupplierCategoryName)
           ) THEN @EndDate ELSE su.EndDate END
    FROM dbo.DimSuppliers su
    WHERE su.EndDate IS NULL
      AND EXISTS (SELECT 1 FROM dbo.Suppliers_Stage stg WHERE stg.FullName = su.FullName);

    INSERT INTO dbo.Suppliers_Preload
    SELECT NEXT VALUE FOR dbo.SupplierKey,
           stg.FullName, stg.PhoneNumber, stg.FaxNumber, stg.WebsiteURL, stg.SupplierCategoryName,
           @StartDate, NULL
    FROM dbo.Suppliers_Stage stg
    WHERE NOT EXISTS (SELECT 1 FROM dbo.DimSuppliers su WHERE stg.FullName = su.FullName);

    INSERT INTO dbo.Suppliers_Preload
    SELECT su.SupplierKey, su.FullName, su.PhoneNumber, su.FaxNumber,
           su.WebsiteURL, su.SupplierCategoryName, su.StartDate, @EndDate
    FROM dbo.DimSuppliers su
    WHERE su.EndDate IS NULL
      AND NOT EXISTS (SELECT 1 FROM dbo.Suppliers_Stage stg WHERE stg.FullName = su.FullName);

    PRINT 'Suppliers_Transform: done.';
END;
GO

-- Orders_Transform (FactSales)
CREATE OR ALTER PROCEDURE dbo.Orders_Transform
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.Orders_Stage)
        RAISERROR('Orders_Transform: Orders_Stage is empty.', 16, 1);
    TRUNCATE TABLE dbo.Orders_Preload;

    INSERT INTO dbo.Orders_Preload
    SELECT cu.CustomerKey, loc.LocationKey, pr.ProductKey,
           sp.SalespersonKey, su.SupplierKey,
           CAST(YEAR(ord.OrderDate) * 10000 + MONTH(ord.OrderDate) * 100 + DAY(ord.OrderDate) AS INT),
           SUM(ord.Quantity), AVG(ord.UnitPrice), AVG(ord.TaxRate),
           SUM(ord.Quantity * ord.UnitPrice),
           SUM(ord.Quantity * ord.UnitPrice * (1 + ord.TaxRate / 100))
    FROM dbo.Orders_Stage ord
    JOIN dbo.Customers_Preload cu ON ord.CustomerName = cu.CustomerName AND cu.EndDate IS NULL
    JOIN dbo.Location_Preload loc ON ord.CityName = loc.CityName
        AND ord.StateProvinceName = loc.StateProvName AND ord.CountryName = loc.CountryName
    JOIN dbo.Products_Preload pr ON ord.StockItemName = pr.ProductName AND pr.EndDate IS NULL
    JOIN dbo.SalesPeople_Preload sp ON ord.LogonName = sp.LogonName
    JOIN dbo.Suppliers_Preload su ON ord.SupplierName = su.FullName AND su.EndDate IS NULL
    GROUP BY cu.CustomerKey, loc.LocationKey, pr.ProductKey,
             sp.SalespersonKey, su.SupplierKey, ord.OrderDate;

    PRINT 'Orders_Transform: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows.';
END;
GO

/* REQUIREMENT 6 - Load (4 marks) */

-- ============================================================
-- LOAD STORED PROCEDURES (DELETE + INSERT with transaction)
-- ============================================================

-- FK constraints are kept per class requirement (Week 9 homework)
-- Temporarily disabled during DELETE+INSERT to avoid FK conflicts with FactSales

CREATE OR ALTER PROCEDURE dbo.Location_Load
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        ALTER TABLE dbo.FactSales NOCHECK CONSTRAINT FK_FactSales_DimLocation;
        SET IDENTITY_INSERT dbo.DimLocation ON;
        DELETE loc FROM dbo.DimLocation loc JOIN dbo.Location_Preload pl ON loc.LocationKey = pl.LocationKey;
        INSERT INTO dbo.DimLocation (LocationKey, CityName, StateProvCode, StateProvName, CountryName, CountryFormalName)
        SELECT LocationKey, CityName, StateProvCode, StateProvName, CountryName, CountryFormalName FROM dbo.Location_Preload;
        SET IDENTITY_INSERT dbo.DimLocation OFF;
        ALTER TABLE dbo.FactSales WITH CHECK CHECK CONSTRAINT FK_FactSales_DimLocation;
        COMMIT TRANSACTION;
        PRINT 'Location_Load: OK.';
    END TRY
    BEGIN CATCH ROLLBACK TRANSACTION; THROW; END CATCH
END;
GO

CREATE OR ALTER PROCEDURE dbo.Customers_Load
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        ALTER TABLE dbo.FactSales NOCHECK CONSTRAINT FK_FactSales_DimCustomers;
        SET IDENTITY_INSERT dbo.DimCustomers ON;
        DELETE cu FROM dbo.DimCustomers cu JOIN dbo.Customers_Preload pl ON cu.CustomerKey = pl.CustomerKey;
        INSERT INTO dbo.DimCustomers (CustomerKey, CustomerName, CustomerCategoryName, DeliveryCityName, DeliveryStateProvCode, DeliveryCountryName, PostalCityName, PostalStateProvCode, PostalCountryName, StartDate, EndDate)
        SELECT CustomerKey, CustomerName, CustomerCategoryName, DeliveryCityName, DeliveryStateProvCode, DeliveryCountryName, PostalCityName, PostalStateProvCode, PostalCountryName, StartDate, EndDate FROM dbo.Customers_Preload;
        SET IDENTITY_INSERT dbo.DimCustomers OFF;
        ALTER TABLE dbo.FactSales WITH CHECK CHECK CONSTRAINT FK_FactSales_DimCustomers;
        COMMIT TRANSACTION;
        PRINT 'Customers_Load: OK.';
    END TRY
    BEGIN CATCH ROLLBACK TRANSACTION; THROW; END CATCH
END;
GO

CREATE OR ALTER PROCEDURE dbo.Products_Load
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        ALTER TABLE dbo.FactSales NOCHECK CONSTRAINT FK_FactSales_DimProducts;
        SET IDENTITY_INSERT dbo.DimProducts ON;
        DELETE pr FROM dbo.DimProducts pr JOIN dbo.Products_Preload pl ON pr.ProductKey = pl.ProductKey;
        INSERT INTO dbo.DimProducts (ProductKey, ProductName, ProductColour, ProductBrand, ProductSize, StartDate, EndDate)
        SELECT ProductKey, ProductName, ProductColour, ProductBrand, ProductSize, StartDate, EndDate FROM dbo.Products_Preload;
        SET IDENTITY_INSERT dbo.DimProducts OFF;
        ALTER TABLE dbo.FactSales WITH CHECK CHECK CONSTRAINT FK_FactSales_DimProducts;
        COMMIT TRANSACTION;
        PRINT 'Products_Load: OK.';
    END TRY
    BEGIN CATCH ROLLBACK TRANSACTION; THROW; END CATCH
END;
GO

CREATE OR ALTER PROCEDURE dbo.SalesPeople_Load
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        ALTER TABLE dbo.FactSales NOCHECK CONSTRAINT FK_FactSales_DimSalesPeople;
        SET IDENTITY_INSERT dbo.DimSalesPeople ON;
        DELETE sp FROM dbo.DimSalesPeople sp JOIN dbo.SalesPeople_Preload pl ON sp.SalespersonKey = pl.SalespersonKey;
        INSERT INTO dbo.DimSalesPeople (SalespersonKey, FullName, PreferredName, LogonName, PhoneNumber, FaxNumber, EmailAddress)
        SELECT SalespersonKey, FullName, PreferredName, LogonName, PhoneNumber, FaxNumber, EmailAddress FROM dbo.SalesPeople_Preload;
        SET IDENTITY_INSERT dbo.DimSalesPeople OFF;
        ALTER TABLE dbo.FactSales WITH CHECK CHECK CONSTRAINT FK_FactSales_DimSalesPeople;
        COMMIT TRANSACTION;
        PRINT 'SalesPeople_Load: OK.';
    END TRY
    BEGIN CATCH ROLLBACK TRANSACTION; THROW; END CATCH
END;
GO

CREATE OR ALTER PROCEDURE dbo.Suppliers_Load
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        ALTER TABLE dbo.FactSales NOCHECK CONSTRAINT FK_FactSales_DimSuppliers;
        SET IDENTITY_INSERT dbo.DimSuppliers ON;
        DELETE su FROM dbo.DimSuppliers su JOIN dbo.Suppliers_Preload pl ON su.SupplierKey = pl.SupplierKey;
        INSERT INTO dbo.DimSuppliers (SupplierKey, FullName, PhoneNumber, FaxNumber, WebsiteURL, SupplierCategoryName, StartDate, EndDate)
        SELECT SupplierKey, FullName, PhoneNumber, FaxNumber, WebsiteURL, SupplierCategoryName, StartDate, EndDate FROM dbo.Suppliers_Preload;
        SET IDENTITY_INSERT dbo.DimSuppliers OFF;
        ALTER TABLE dbo.FactSales WITH CHECK CHECK CONSTRAINT FK_FactSales_DimSuppliers;
        COMMIT TRANSACTION;
        PRINT 'Suppliers_Load: OK.';
    END TRY
    BEGIN CATCH ROLLBACK TRANSACTION; THROW; END CATCH
END;
GO

CREATE OR ALTER PROCEDURE dbo.Orders_Load
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT INTO dbo.FactSales SELECT * FROM dbo.Orders_Preload;
        COMMIT TRANSACTION;
        PRINT 'Orders_Load: OK.';
    END TRY
    BEGIN CATCH ROLLBACK TRANSACTION; THROW; END CATCH
END;
GO

/* REQUIREMENT 7 - Execute 4 days + Req 3 queries (2 marks) */

-- ============================================================
-- Run full ETL for 2013-01-01 to 2013-01-04
-- ============================================================

DECLARE @Date DATE = '2013-01-01';
DECLARE @EndDate DATE = '2013-01-04';

WHILE @Date <= @EndDate
BEGIN
    PRINT '===== Processing: ' + CAST(@Date AS VARCHAR) + ' =====';
    EXEC dbo.Customers_Extract;
    EXEC dbo.Products_Extract;
    EXEC dbo.SalesPeople_Extract;
    EXEC dbo.Suppliers_Extract;
    EXEC dbo.Orders_Extract @OrderDate = @Date;
    EXEC dbo.Location_Transform;
    EXEC dbo.Customers_Transform;
    EXEC dbo.Products_Transform;
    EXEC dbo.SalesPeople_Transform;
    EXEC dbo.Suppliers_Transform;
    EXEC dbo.Orders_Transform;
    EXEC dbo.Location_Load;
    EXEC dbo.Customers_Load;
    EXEC dbo.Products_Load;
    EXEC dbo.SalesPeople_Load;
    EXEC dbo.Suppliers_Load;
    EXEC dbo.Orders_Load;
    SET @Date = DATEADD(DAY, 1, @Date);
END;
GO

-- ETL Pipeline Verification: summary of loaded data after 4-day run (2013-01-01 to 2013-01-04)
SELECT 
    (SELECT COUNT(*) FROM dbo.FactSales) AS FactRows,
    (SELECT COUNT(*) FROM dbo.DimCustomers WHERE EndDate IS NULL) AS ActiveCustomers,
    (SELECT COUNT(*) FROM dbo.DimCustomers WHERE EndDate IS NOT NULL) AS ExpiredCustomers,
    (SELECT COUNT(*) FROM dbo.DimProducts WHERE EndDate IS NULL) AS ActiveProducts,
    (SELECT COUNT(*) FROM dbo.DimSuppliers WHERE EndDate IS NULL) AS ActiveSuppliers,
    (SELECT COUNT(DISTINCT DateKey) FROM dbo.FactSales) AS DaysLoaded,
    (SELECT SUM(TotalAfterTax) FROM dbo.FactSales) AS TotalRevenue;
GO

-- ============================================================
-- Req 3 Query 1: Supplier Performance by City
-- Business Question: Which suppliers generate the most revenue in each city?
-- Action: Increase stock of dominant suppliers per region, diversify high-dependency cities.
-- ============================================================
SELECT '=== Query 1: Supplier Performance by City ===' AS [Analysis];
GO

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

-- >> Conclusion:
-- Litware (Packaging) ranks #1 in every city — revenue share from 56.9% (New Zion, SC) to 99.7% (Airport Drive, MO).
-- This is 5-10x Supplier B in most cities.
-- Action: increase Litware stock (dominant driver), but diversify in high-dependency cities
--         (Airport Drive 99.7% = single point of failure).
-- New Zion is the healthiest city with 4 active suppliers.

-- ============================================================
-- Req 3 Query 2: Salesperson × Supplier Performance
-- Business Question: Which salesperson sells which supplier's products best?
-- Action: Match salespeople to suppliers they're most effective with.
-- ============================================================
SELECT '=== Query 2: Salesperson x Supplier Performance ===' AS [Analysis];
GO

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

-- >> Conclusion:
-- Litware dominates all salespeople at 59-63% — except Hudson Hollinworth where Fabrikam (Clothing) leads at 52%.
-- Action: assign Hudson to Clothing-heavy regions, deploy Amy/Anthony/Jack for Packaging push.
-- Lily Code has 15% Toy Supplier (vs 4-6% others) — potential Toy category specialist.
-- Overall Litware dependency needs training/incentives to grow Fabrikam and Northwind revenue.

-- ============================================================
-- Req 3 Query 3: Salesperson Efficiency by Customer Category
-- Business Question: Which salesperson-category assignments yield the highest revenue per customer?
-- Action: Reassign salespeople to customer categories where they generate the most revenue per account.
-- ============================================================
SELECT '=== Query 3: Salesperson Efficiency by Customer Category ===' AS [Analysis];
GO

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

-- >> Conclusion:
-- Novelty Shop has largest total revenue but evenly spread (7-14% per salesperson) = low risk.
-- Lily Code leads Gift Store at 27%, Amy Trefl leads Supermarket at 28%.
-- Kayla Woodcock has highest RevenuePerCustomer ($9,085 from 1 Supermarket customer).
-- Action: assign Lily to more Gift Store, Amy to more Supermarket, Kayla as high-value customer specialist.
-- Anthony Grosse can handle Corporate + Novelty Shop (top 3 in both).