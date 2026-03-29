-- ============================================================
-- Req 1: Dimensional Model Tables
-- WWI Data Mart Star Schema
-- Group 11 | PROG3240 Winter 2026
-- ============================================================
-- Run against: WWI_DM database
-- Source:      WideWorldImporters (OLTP)
-- ============================================================

USE WWI_DM;
GO

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
