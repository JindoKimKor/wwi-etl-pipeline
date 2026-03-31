USE WWI_DM;
GO

-- ============================================================
-- DROP PRELOAD TABLES IF THEY EXIST
-- ============================================================
DROP TABLE IF EXISTS dbo.Location_Preload;
DROP TABLE IF EXISTS dbo.Customers_Preload;
DROP TABLE IF EXISTS dbo.Products_Preload;
DROP TABLE IF EXISTS dbo.SalesPeople_Preload;
DROP TABLE IF EXISTS dbo.Suppliers_Preload;
DROP TABLE IF EXISTS dbo.Orders_Preload;
GO

-- ============================================================
-- CREATE PRELOAD TABLES
-- ============================================================

-- Location Preload
CREATE TABLE dbo.Location_Preload (
    LocationKey         INT             NOT NULL,
    CityName            NVARCHAR(50)    NULL,
    StateProvCode       NVARCHAR(5)     NULL,
    StateProvName       NVARCHAR(50)    NULL,
    CountryName         NVARCHAR(60)    NULL,
    CountryFormalName   NVARCHAR(60)    NULL,
    CONSTRAINT PK_Location_Preload PRIMARY KEY CLUSTERED (LocationKey)
);
GO

-- Customers Preload
CREATE TABLE dbo.Customers_Preload (
    CustomerKey             INT             NOT NULL,
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
    CONSTRAINT PK_Customers_Preload PRIMARY KEY CLUSTERED (CustomerKey)
);
GO

-- Products Preload
CREATE TABLE dbo.Products_Preload (
    ProductKey      INT             NOT NULL,
    ProductName     NVARCHAR(100)   NULL,
    ProductColour   NVARCHAR(20)    NULL,
    ProductBrand    NVARCHAR(50)    NULL,
    ProductSize     NVARCHAR(20)    NULL,
    StartDate       DATE            NOT NULL,
    EndDate         DATE            NULL,
    CONSTRAINT PK_Products_Preload PRIMARY KEY CLUSTERED (ProductKey)
);
GO

-- SalesPeople Preload
CREATE TABLE dbo.SalesPeople_Preload (
    SalespersonKey  INT             NOT NULL,
    FullName        NVARCHAR(50)    NULL,
    PreferredName   NVARCHAR(50)    NULL,
    LogonName       NVARCHAR(50)    NULL,
    PhoneNumber     NVARCHAR(20)    NULL,
    FaxNumber       NVARCHAR(20)    NULL,
    EmailAddress    NVARCHAR(256)   NULL,
    CONSTRAINT PK_SalesPeople_Preload PRIMARY KEY CLUSTERED (SalespersonKey)
);
GO

-- Suppliers Preload
CREATE TABLE dbo.Suppliers_Preload (
    SupplierKey             INT             NOT NULL,
    FullName                NVARCHAR(100)   NULL,
    PhoneNumber             NVARCHAR(20)    NULL,
    FaxNumber               NVARCHAR(20)    NULL,
    WebsiteURL              NVARCHAR(256)   NULL,
    SupplierCategoryName    NVARCHAR(50)    NULL,
    StartDate               DATE            NOT NULL,
    EndDate                 DATE            NULL,
    CONSTRAINT PK_Suppliers_Preload PRIMARY KEY CLUSTERED (SupplierKey)
);
GO

-- Orders Preload (Fact Table)
CREATE TABLE dbo.Orders_Preload (
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
    TotalAfterTax   DECIMAL(18,2)   NOT NULL
);
GO
