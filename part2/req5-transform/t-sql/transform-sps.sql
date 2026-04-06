-- ============================================================
-- Req 5: Sequences + Transform Stored Procedures
-- Group 11 | PROG3240 Winter 2026
-- ============================================================
-- Sequences: standalone counters for surrogate keys (not IDENTITY)
-- Transform: Stage → PreLoad (business key → surrogate key + SCD logic)
-- PreLoad tables must exist first (create-preload-tables.sql)
-- ============================================================

USE WWI_DM;
GO

-- ============================================================
-- SEQUENCES (one per SCD Type 1/2 Dim)
-- Used instead of IDENTITY because PreLoad tables get TRUNCATEd
-- each run — Sequence values persist across truncates
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
-- Location_Transform (SCD Type 1)
-- Business key: CityName + StateProvName + CountryName
-- New → Sequence for key. Existing → use existing key.
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.Location_Transform
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.Customers_Stage)
        RAISERROR('Location_Transform: Customers_Stage is empty.', 16, 1);
    TRUNCATE TABLE dbo.Location_Preload;

    -- New records: not in DimLocation yet → assign new key via Sequence
    INSERT INTO dbo.Location_Preload (
        LocationKey, CityName, StateProvCode, StateProvName, CountryName, CountryFormalName
    )
    SELECT NEXT VALUE FOR dbo.LocationKey,
           cu.DeliveryCityName,
           cu.DeliveryStateProvCode,
           cu.DeliveryStateProvName,
           cu.DeliveryCountryName,
           cu.DeliveryCountryFormalName
    FROM dbo.Customers_Stage cu
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.DimLocation loc
        WHERE cu.DeliveryCityName = loc.CityName
          AND cu.DeliveryStateProvName = loc.StateProvName
          AND cu.DeliveryCountryName = loc.CountryName
    )
    GROUP BY cu.DeliveryCityName, cu.DeliveryStateProvCode,
             cu.DeliveryStateProvName, cu.DeliveryCountryName,
             cu.DeliveryCountryFormalName;

    -- Existing records: already in DimLocation → keep existing key
    INSERT INTO dbo.Location_Preload (
        LocationKey, CityName, StateProvCode, StateProvName, CountryName, CountryFormalName
    )
    SELECT loc.LocationKey,
           cu.DeliveryCityName,
           cu.DeliveryStateProvCode,
           cu.DeliveryStateProvName,
           cu.DeliveryCountryName,
           cu.DeliveryCountryFormalName
    FROM dbo.Customers_Stage cu
    JOIN dbo.DimLocation loc
        ON cu.DeliveryCityName = loc.CityName
       AND cu.DeliveryStateProvName = loc.StateProvName
       AND cu.DeliveryCountryName = loc.CountryName
    GROUP BY loc.LocationKey, cu.DeliveryCityName, cu.DeliveryStateProvCode,
             cu.DeliveryStateProvName, cu.DeliveryCountryName,
             cu.DeliveryCountryFormalName;

    PRINT 'Location_Transform: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows.';
END;
GO

-- ============================================================
-- SalesPeople_Transform (SCD Type 1)
-- Business key: LogonName
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.SalesPeople_Transform
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.SalesPeople_Stage)
        RAISERROR('SalesPeople_Transform: SalesPeople_Stage is empty.', 16, 1);
    TRUNCATE TABLE dbo.SalesPeople_Preload;

    -- New records
    INSERT INTO dbo.SalesPeople_Preload (
        SalespersonKey, FullName, PreferredName, LogonName,
        PhoneNumber, FaxNumber, EmailAddress
    )
    SELECT NEXT VALUE FOR dbo.SalespersonKey,
           stg.FullName, stg.PreferredName, stg.LogonName,
           stg.PhoneNumber, stg.FaxNumber, stg.EmailAddress
    FROM dbo.SalesPeople_Stage stg
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.DimSalesPeople sp
        WHERE stg.LogonName = sp.LogonName
    );

    -- Existing records
    INSERT INTO dbo.SalesPeople_Preload (
        SalespersonKey, FullName, PreferredName, LogonName,
        PhoneNumber, FaxNumber, EmailAddress
    )
    SELECT sp.SalespersonKey,
           stg.FullName, stg.PreferredName, stg.LogonName,
           stg.PhoneNumber, stg.FaxNumber, stg.EmailAddress
    FROM dbo.SalesPeople_Stage stg
    JOIN dbo.DimSalesPeople sp
        ON stg.LogonName = sp.LogonName;

    PRINT 'SalesPeople_Transform: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows.';
END;
GO

-- ============================================================
-- Customers_Transform (SCD Type 2)
-- Business key: CustomerName
-- 4 cases: match+no change / match+changed / new / missing→expire
-- ============================================================

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

    -- Case b: match + attribute changed → new record with new key
    INSERT INTO dbo.Customers_Preload
    SELECT NEXT VALUE FOR dbo.CustomerKey,
           stg.CustomerName, stg.CustomerCategoryName,
           stg.DeliveryCityName, stg.DeliveryStateProvCode, stg.DeliveryCountryName,
           stg.PostalCityName, stg.PostalStateProvCode, stg.PostalCountryName,
           @StartDate, NULL
    FROM dbo.Customers_Stage stg
    JOIN dbo.DimCustomers cu
        ON stg.CustomerName = cu.CustomerName AND cu.EndDate IS NULL
    WHERE stg.CustomerCategoryName <> cu.CustomerCategoryName
       OR stg.DeliveryCityName <> cu.DeliveryCityName
       OR stg.DeliveryStateProvCode <> cu.DeliveryStateProvCode
       OR stg.DeliveryCountryName <> cu.DeliveryCountryName
       OR stg.PostalCityName <> cu.PostalCityName
       OR stg.PostalStateProvCode <> cu.PostalStateProvCode
       OR stg.PostalCountryName <> cu.PostalCountryName;

    -- Case a: match + no change → keep existing record as-is
    -- Also expires changed records (case b old version)
    INSERT INTO dbo.Customers_Preload
    SELECT cu.CustomerKey, cu.CustomerName, cu.CustomerCategoryName,
           cu.DeliveryCityName, cu.DeliveryStateProvCode, cu.DeliveryCountryName,
           cu.PostalCityName, cu.PostalStateProvCode, cu.PostalCountryName,
           cu.StartDate,
           CASE
               WHEN EXISTS (
                   SELECT 1 FROM dbo.Customers_Stage stg
                   WHERE stg.CustomerName = cu.CustomerName
                     AND (stg.CustomerCategoryName <> cu.CustomerCategoryName
                       OR stg.DeliveryCityName <> cu.DeliveryCityName
                       OR stg.DeliveryStateProvCode <> cu.DeliveryStateProvCode
                       OR stg.DeliveryCountryName <> cu.DeliveryCountryName
                       OR stg.PostalCityName <> cu.PostalCityName
                       OR stg.PostalStateProvCode <> cu.PostalStateProvCode
                       OR stg.PostalCountryName <> cu.PostalCountryName)
               ) THEN @EndDate
               ELSE cu.EndDate
           END
    FROM dbo.DimCustomers cu
    WHERE cu.EndDate IS NULL
      AND EXISTS (SELECT 1 FROM dbo.Customers_Stage stg WHERE stg.CustomerName = cu.CustomerName);

    -- Case c: new record (not in DW)
    INSERT INTO dbo.Customers_Preload
    SELECT NEXT VALUE FOR dbo.CustomerKey,
           stg.CustomerName, stg.CustomerCategoryName,
           stg.DeliveryCityName, stg.DeliveryStateProvCode, stg.DeliveryCountryName,
           stg.PostalCityName, stg.PostalStateProvCode, stg.PostalCountryName,
           @StartDate, NULL
    FROM dbo.Customers_Stage stg
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.DimCustomers cu WHERE stg.CustomerName = cu.CustomerName
    );

    -- Case d: missing from stage → expire
    INSERT INTO dbo.Customers_Preload
    SELECT cu.CustomerKey, cu.CustomerName, cu.CustomerCategoryName,
           cu.DeliveryCityName, cu.DeliveryStateProvCode, cu.DeliveryCountryName,
           cu.PostalCityName, cu.PostalStateProvCode, cu.PostalCountryName,
           cu.StartDate, @EndDate
    FROM dbo.DimCustomers cu
    WHERE cu.EndDate IS NULL
      AND NOT EXISTS (
          SELECT 1 FROM dbo.Customers_Stage stg WHERE stg.CustomerName = cu.CustomerName
      );

    PRINT 'Customers_Transform: done.';
END;
GO

-- ============================================================
-- Products_Transform (SCD Type 2)
-- Business key: ProductName
-- Same 4-case pattern as Customers
-- ============================================================

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

    -- Case b: changed
    INSERT INTO dbo.Products_Preload
    SELECT NEXT VALUE FOR dbo.ProductKey,
           stg.ProductName, stg.ProductColour, stg.ProductBrand, stg.ProductSize,
           @StartDate, NULL
    FROM dbo.Products_Stage stg
    JOIN dbo.DimProducts pr
        ON stg.ProductName = pr.ProductName AND pr.EndDate IS NULL
    WHERE ISNULL(stg.ProductColour,'') <> ISNULL(pr.ProductColour,'')
       OR ISNULL(stg.ProductBrand,'') <> ISNULL(pr.ProductBrand,'')
       OR ISNULL(stg.ProductSize,'') <> ISNULL(pr.ProductSize,'');

    -- Case a: no change + expire old for case b
    INSERT INTO dbo.Products_Preload
    SELECT pr.ProductKey, pr.ProductName, pr.ProductColour,
           pr.ProductBrand, pr.ProductSize, pr.StartDate,
           CASE
               WHEN EXISTS (
                   SELECT 1 FROM dbo.Products_Stage stg
                   WHERE stg.ProductName = pr.ProductName
                     AND (ISNULL(stg.ProductColour,'') <> ISNULL(pr.ProductColour,'')
                       OR ISNULL(stg.ProductBrand,'') <> ISNULL(pr.ProductBrand,'')
                       OR ISNULL(stg.ProductSize,'') <> ISNULL(pr.ProductSize,''))
               ) THEN @EndDate
               ELSE pr.EndDate
           END
    FROM dbo.DimProducts pr
    WHERE pr.EndDate IS NULL
      AND EXISTS (SELECT 1 FROM dbo.Products_Stage stg WHERE stg.ProductName = pr.ProductName);

    -- Case c: new
    INSERT INTO dbo.Products_Preload
    SELECT NEXT VALUE FOR dbo.ProductKey,
           stg.ProductName, stg.ProductColour, stg.ProductBrand, stg.ProductSize,
           @StartDate, NULL
    FROM dbo.Products_Stage stg
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.DimProducts pr WHERE stg.ProductName = pr.ProductName
    );

    -- Case d: expire missing
    INSERT INTO dbo.Products_Preload
    SELECT pr.ProductKey, pr.ProductName, pr.ProductColour,
           pr.ProductBrand, pr.ProductSize, pr.StartDate, @EndDate
    FROM dbo.DimProducts pr
    WHERE pr.EndDate IS NULL
      AND NOT EXISTS (
          SELECT 1 FROM dbo.Products_Stage stg WHERE stg.ProductName = pr.ProductName
      );

    PRINT 'Products_Transform: done.';
END;
GO

-- ============================================================
-- Suppliers_Transform (SCD Type 2)
-- Business key: FullName
-- Same 4-case pattern as Customers
-- ============================================================

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

    -- Case b: changed
    INSERT INTO dbo.Suppliers_Preload
    SELECT NEXT VALUE FOR dbo.SupplierKey,
           stg.FullName, stg.PhoneNumber, stg.FaxNumber,
           stg.WebsiteURL, stg.SupplierCategoryName,
           @StartDate, NULL
    FROM dbo.Suppliers_Stage stg
    JOIN dbo.DimSuppliers su
        ON stg.FullName = su.FullName AND su.EndDate IS NULL
    WHERE stg.PhoneNumber <> su.PhoneNumber
       OR stg.FaxNumber <> su.FaxNumber
       OR stg.WebsiteURL <> su.WebsiteURL
       OR stg.SupplierCategoryName <> su.SupplierCategoryName;

    -- Case a: no change + expire old for case b
    INSERT INTO dbo.Suppliers_Preload
    SELECT su.SupplierKey, su.FullName, su.PhoneNumber, su.FaxNumber,
           su.WebsiteURL, su.SupplierCategoryName, su.StartDate,
           CASE
               WHEN EXISTS (
                   SELECT 1 FROM dbo.Suppliers_Stage stg
                   WHERE stg.FullName = su.FullName
                     AND (stg.PhoneNumber <> su.PhoneNumber
                       OR stg.FaxNumber <> su.FaxNumber
                       OR stg.WebsiteURL <> su.WebsiteURL
                       OR stg.SupplierCategoryName <> su.SupplierCategoryName)
               ) THEN @EndDate
               ELSE su.EndDate
           END
    FROM dbo.DimSuppliers su
    WHERE su.EndDate IS NULL
      AND EXISTS (SELECT 1 FROM dbo.Suppliers_Stage stg WHERE stg.FullName = su.FullName);

    -- Case c: new
    INSERT INTO dbo.Suppliers_Preload
    SELECT NEXT VALUE FOR dbo.SupplierKey,
           stg.FullName, stg.PhoneNumber, stg.FaxNumber,
           stg.WebsiteURL, stg.SupplierCategoryName,
           @StartDate, NULL
    FROM dbo.Suppliers_Stage stg
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.DimSuppliers su WHERE stg.FullName = su.FullName
    );

    -- Case d: expire missing
    INSERT INTO dbo.Suppliers_Preload
    SELECT su.SupplierKey, su.FullName, su.PhoneNumber, su.FaxNumber,
           su.WebsiteURL, su.SupplierCategoryName, su.StartDate, @EndDate
    FROM dbo.DimSuppliers su
    WHERE su.EndDate IS NULL
      AND NOT EXISTS (
          SELECT 1 FROM dbo.Suppliers_Stage stg WHERE stg.FullName = su.FullName
      );

    PRINT 'Suppliers_Transform: done.';
END;
GO

-- ============================================================
-- Orders_Transform (FactSales)
-- Look up surrogate keys from PreLoad tables by business key
-- Aggregate measures
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.Orders_Transform
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.Orders_Stage)
        RAISERROR('Orders_Transform: Orders_Stage is empty.', 16, 1);
    TRUNCATE TABLE dbo.Orders_Preload;

    INSERT INTO dbo.Orders_Preload (
        CustomerKey, LocationKey, ProductKey, SalespersonKey, SupplierKey, DateKey,
        Quantity, UnitPrice, TaxRate, TotalBeforeTax, TotalAfterTax
    )
    SELECT cu.CustomerKey,
           loc.LocationKey,
           pr.ProductKey,
           sp.SalespersonKey,
           su.SupplierKey,
           CAST(YEAR(ord.OrderDate) * 10000 + MONTH(ord.OrderDate) * 100 + DAY(ord.OrderDate) AS INT),
           SUM(ord.Quantity),
           AVG(ord.UnitPrice),
           AVG(ord.TaxRate),
           SUM(ord.Quantity * ord.UnitPrice),
           SUM(ord.Quantity * ord.UnitPrice * (1 + ord.TaxRate / 100))
    FROM dbo.Orders_Stage ord
    JOIN dbo.Customers_Preload cu
        ON ord.CustomerName = cu.CustomerName AND cu.EndDate IS NULL
    JOIN dbo.Location_Preload loc
        ON ord.CityName = loc.CityName AND ord.StateProvinceName = loc.StateProvName
           AND ord.CountryName = loc.CountryName
    JOIN dbo.Products_Preload pr
        ON ord.StockItemName = pr.ProductName AND pr.EndDate IS NULL
    JOIN dbo.SalesPeople_Preload sp
        ON ord.LogonName = sp.LogonName
    JOIN dbo.Suppliers_Preload su
        ON ord.SupplierName = su.FullName AND su.EndDate IS NULL
    GROUP BY cu.CustomerKey, loc.LocationKey, pr.ProductKey,
             sp.SalespersonKey, su.SupplierKey, ord.OrderDate;

    PRINT 'Orders_Transform: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows.';
END;
GO
