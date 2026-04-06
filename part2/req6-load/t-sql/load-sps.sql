-- ============================================================
-- Req 6: Load Stored Procedures
-- Group 11 | PROG3240 Winter 2026
-- ============================================================
-- Load: PreLoad → final Dim/Fact tables
-- Dim Load: NOCHECK FK → DELETE + INSERT → CHECK FK (transaction safe)
-- Fact Load: INSERT only (facts are additive)
-- Order: Dims first, then Fact (FK dependency)
-- ============================================================

USE WWI_DM;
GO

-- FK constraints kept per class requirement (Week 9 homework)
-- Temporarily disabled during DELETE+INSERT to avoid FK conflicts with FactSales
-- In production DWs, FKs are often omitted entirely

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
