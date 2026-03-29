-- ============================================================
-- Req 2: DimDate Stored Procedure + 5 Year Load
-- Group 11 | PROG3240 Winter 2026
-- ============================================================
-- Run against: WWI_DM database (after Req 1 creates the tables)
-- DimDate is calculated — no source table in WideWorldImporters
-- Each column is derived from a single DATE input
-- ============================================================

USE WWI_DM;
GO

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
-- Each iteration calls the SP for one day
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

-- ============================================================
-- Verify
-- ============================================================

SELECT COUNT(*) AS TotalRows FROM dbo.DimDate;
-- Expected: 1,827

SELECT * FROM dbo.DimDate WHERE CYear = 2013 AND CMonth = 1;
-- Expected: 31 rows (January 2013)

SELECT DateKey, DateValue, DayOfWeekName FROM dbo.DimDate WHERE DateKey = 20130101;
-- Expected: 20130101 | 2013-01-01 | Tuesday
