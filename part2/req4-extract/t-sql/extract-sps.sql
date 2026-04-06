-- ============================================================
-- Req 4: Extract Stored Procedures
-- Group 11 | PROG3240 Winter 2026
-- ============================================================
-- Each SP: TRUNCATE Stage → INSERT from WideWorldImporters JOINs
-- Stage tables must exist first (create-staging-tables.sql)
-- ============================================================

USE WWI_DM;
GO

-- ============================================================
-- Customers_Extract
-- Source: Customers + CustomerCategories + Cities + StateProvinces + Countries
-- Serves both DimCustomers and DimLocation
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.Customers_Extract
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    TRUNCATE TABLE dbo.Customers_Stage;

    WITH CityDetails AS (
        SELECT ci.CityID,
               ci.CityName,
               sp.StateProvinceCode,
               sp.StateProvinceName,
               co.CountryName,
               co.FormalName
        FROM WideWorldImporters.Application.Cities ci
        LEFT JOIN WideWorldImporters.Application.StateProvinces sp
            ON ci.StateProvinceID = sp.StateProvinceID
        LEFT JOIN WideWorldImporters.Application.Countries co
            ON sp.CountryID = co.CountryID
    )
    INSERT INTO dbo.Customers_Stage (
        CustomerName, CustomerCategoryName,
        DeliveryCityName, DeliveryStateProvCode, DeliveryStateProvName,
        DeliveryCountryName, DeliveryCountryFormalName,
        PostalCityName, PostalStateProvCode, PostalStateProvName,
        PostalCountryName, PostalCountryFormalName
    )
    SELECT cust.CustomerName,
           cat.CustomerCategoryName,
           dc.CityName,
           dc.StateProvinceCode,
           dc.StateProvinceName,
           dc.CountryName,
           dc.FormalName,
           pc.CityName,
           pc.StateProvinceCode,
           pc.StateProvinceName,
           pc.CountryName,
           pc.FormalName
    FROM WideWorldImporters.Sales.Customers cust
    LEFT JOIN WideWorldImporters.Sales.CustomerCategories cat
        ON cust.CustomerCategoryID = cat.CustomerCategoryID
    LEFT JOIN CityDetails dc
        ON cust.DeliveryCityID = dc.CityID
    LEFT JOIN CityDetails pc
        ON cust.PostalCityID = pc.CityID;

    DECLARE @RowCt INT = @@ROWCOUNT;
    IF @RowCt = 0
        RAISERROR('Customers_Extract: no rows extracted.', 16, 1);
    PRINT 'Customers_Extract: ' + CAST(@RowCt AS VARCHAR) + ' rows.';
END;
GO

-- ============================================================
-- Products_Extract
-- Source: StockItems + Colors
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.Products_Extract
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    TRUNCATE TABLE dbo.Products_Stage;

    INSERT INTO dbo.Products_Stage (
        ProductName, ProductColour, ProductBrand, ProductSize
    )
    SELECT si.StockItemName,
           c.ColorName,
           si.Brand,
           si.Size
    FROM WideWorldImporters.Warehouse.StockItems si
    LEFT JOIN WideWorldImporters.Warehouse.Colors c
        ON si.ColorID = c.ColorID;

    DECLARE @RowCt INT = @@ROWCOUNT;
    IF @RowCt = 0
        RAISERROR('Products_Extract: no rows extracted.', 16, 1);
    PRINT 'Products_Extract: ' + CAST(@RowCt AS VARCHAR) + ' rows.';
END;
GO

-- ============================================================
-- SalesPeople_Extract
-- Source: People WHERE IsSalesperson = 1
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.SalesPeople_Extract
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    TRUNCATE TABLE dbo.SalesPeople_Stage;

    INSERT INTO dbo.SalesPeople_Stage (
        FullName, PreferredName, LogonName, PhoneNumber, FaxNumber, EmailAddress
    )
    SELECT FullName,
           PreferredName,
           LogonName,
           PhoneNumber,
           FaxNumber,
           EmailAddress
    FROM WideWorldImporters.Application.People
    WHERE IsSalesperson = 1;

    DECLARE @RowCt INT = @@ROWCOUNT;
    IF @RowCt = 0
        RAISERROR('SalesPeople_Extract: no rows extracted.', 16, 1);
    PRINT 'SalesPeople_Extract: ' + CAST(@RowCt AS VARCHAR) + ' rows.';
END;
GO

-- ============================================================
-- Suppliers_Extract
-- Source: Suppliers + SupplierCategories
-- Assignment addition (not in class)
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.Suppliers_Extract
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    TRUNCATE TABLE dbo.Suppliers_Stage;

    INSERT INTO dbo.Suppliers_Stage (
        FullName, PhoneNumber, FaxNumber, WebsiteURL, SupplierCategoryName
    )
    SELECT s.SupplierName,
           s.PhoneNumber,
           s.FaxNumber,
           s.WebsiteURL,
           sc.SupplierCategoryName
    FROM WideWorldImporters.Purchasing.Suppliers s
    JOIN WideWorldImporters.Purchasing.SupplierCategories sc
        ON s.SupplierCategoryID = sc.SupplierCategoryID;

    DECLARE @RowCt INT = @@ROWCOUNT;
    IF @RowCt = 0
        RAISERROR('Suppliers_Extract: no rows extracted.', 16, 1);
    PRINT 'Suppliers_Extract: ' + CAST(@RowCt AS VARCHAR) + ' rows.';
END;
GO

-- ============================================================
-- Orders_Extract
-- Source: Orders + OrderLines + Customers + Cities + StockItems + People + Suppliers
-- @OrderDate parameter — only extracts orders for that date
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.Orders_Extract
    @OrderDate DATE
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    TRUNCATE TABLE dbo.Orders_Stage;

    INSERT INTO dbo.Orders_Stage (
        OrderDate, Quantity, UnitPrice, TaxRate,
        CustomerName, CityName, StateProvinceName, CountryName,
        StockItemName, LogonName, SupplierName
    )
    SELECT o.OrderDate,
           ol.Quantity,
           ol.UnitPrice,
           ol.TaxRate,
           c.CustomerName,
           ci.CityName,
           sp.StateProvinceName,
           co.CountryName,
           si.StockItemName,
           p.LogonName,
           sup.SupplierName
    FROM WideWorldImporters.Sales.Orders o
    JOIN WideWorldImporters.Sales.OrderLines ol
        ON o.OrderID = ol.OrderID
    JOIN WideWorldImporters.Sales.Customers c
        ON o.CustomerID = c.CustomerID
    JOIN WideWorldImporters.Application.Cities ci
        ON c.DeliveryCityID = ci.CityID
    JOIN WideWorldImporters.Application.StateProvinces sp
        ON ci.StateProvinceID = sp.StateProvinceID
    JOIN WideWorldImporters.Application.Countries co
        ON sp.CountryID = co.CountryID
    JOIN WideWorldImporters.Warehouse.StockItems si
        ON ol.StockItemID = si.StockItemID
    JOIN WideWorldImporters.Application.People p
        ON o.SalespersonPersonID = p.PersonID
    JOIN WideWorldImporters.Purchasing.Suppliers sup
        ON si.SupplierID = sup.SupplierID
    WHERE o.OrderDate = @OrderDate;

    DECLARE @RowCt INT = @@ROWCOUNT;
    IF @RowCt = 0
        RAISERROR('Orders_Extract: no rows for this date.', 16, 1);
    PRINT 'Orders_Extract (' + CAST(@OrderDate AS VARCHAR) + '): ' + CAST(@RowCt AS VARCHAR) + ' rows.';
END;
GO
