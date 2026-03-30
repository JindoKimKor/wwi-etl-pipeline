USE WWI_DM;
GO

-- ============================================================
-- DROP STAGING TABLES IF THEY EXIST
-- ============================================================

DROP TABLE IF EXISTS dbo.Location_Stage;
DROP TABLE IF EXISTS dbo.Customers_Stage;
DROP TABLE IF EXISTS dbo.Products_Stage;
DROP TABLE IF EXISTS dbo.SalesPeople_Stage;
DROP TABLE IF EXISTS dbo.Suppliers_Stage;
DROP TABLE IF EXISTS dbo.Orders_Stage;
GO

-- ============================================================
-- CREATE FLAT STAGING TABLES
-- ============================================================

-- Staging for Location
CREATE TABLE dbo.Location_Stage (
    CityName            NVARCHAR(50)    NULL,
    StateProvCode       NVARCHAR(5)     NULL,
    StateProvName       NVARCHAR(50)    NULL,
    CountryName         NVARCHAR(60)    NULL,
    CountryFormalName   NVARCHAR(60)    NULL
);
GO

-- Staging for Customers
CREATE TABLE dbo.Customers_Stage (
    CustomerName            NVARCHAR(100)   NULL,
    CustomerCategoryName    NVARCHAR(50)    NULL,
    DeliveryCityName        NVARCHAR(50)    NULL,
    DeliveryStateProvCode   NVARCHAR(5)     NULL,
    DeliveryCountryName     NVARCHAR(50)    NULL,
    PostalCityName          NVARCHAR(50)    NULL,
    PostalStateProvCode     NVARCHAR(5)     NULL,
    PostalCountryName       NVARCHAR(50)    NULL
);
GO

-- Staging for Products
CREATE TABLE dbo.Products_Stage (
    ProductName     NVARCHAR(100)   NULL,
    ProductColour   NVARCHAR(20)    NULL,
    ProductBrand    NVARCHAR(50)    NULL,
    ProductSize     NVARCHAR(20)    NULL
);
GO

-- Staging for SalesPeople
CREATE TABLE dbo.SalesPeople_Stage (
    FullName        NVARCHAR(50)    NULL,
    PreferredName   NVARCHAR(50)    NULL,
    LogonName       NVARCHAR(50)    NULL,
    PhoneNumber     NVARCHAR(20)    NULL,
    FaxNumber       NVARCHAR(20)    NULL,
    EmailAddress    NVARCHAR(256)   NULL
);
GO

-- Staging for Suppliers
CREATE TABLE dbo.Suppliers_Stage (
    FullName                NVARCHAR(100)   NULL,
    PhoneNumber             NVARCHAR(20)    NULL,
    FaxNumber               NVARCHAR(20)    NULL,
    WebsiteURL              NVARCHAR(256)   NULL,
    SupplierCategoryName    NVARCHAR(50)    NULL
);
GO

-- Staging for Orders
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
    LogonName           NVARCHAR(50)    NULL
);
GO
