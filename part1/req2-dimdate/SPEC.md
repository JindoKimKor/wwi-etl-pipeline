# Req 2: Date Dimension & Stored Procedure (3 marks)

> DimDate table already created in Req 1. This Req populates it with data.

---

## What are we doing?

In Req 1, we created an empty DimDate table:

```
DateKey | DateValue | CYear | CMonth | DayNo | CQtr | StartOfMonth | EndOfMonth | MonthName | DayOfWeekName
```

Now we need to fill it with 5 years of dates (2012-01-01 ~ 2016-12-31).
Unlike other Dims that extract data from WideWorldImporters, DimDate is **calculated** — every column is derivable from the date itself.

**Why 2012 ~ 2016?**

```
Requirement 2 – Date dimension & Stored Procedure to load it (3 Marks)Create a stored procedure to insert into the date dimension table, using a single DateValue parameter as an input DATE field. Use While Loop to add 5 years date values (starts from CY2012)
```

- Assignment PDF: "add 5 years date values (starts from CY2012)"
- WideWorldImporters data spans 2013 ~ 2016
- Req 7 runs ETL for 2013-01-01 ~ 2013-01-04 — FactSales references DateKey via FK, so DimDate must have those dates **before** any Fact data is loaded
- 2012 = buffer year before the data starts

## Why a Stored Procedure?

The assignment says: "Create a stored procedure to insert into the date dimension table, using a single DateValue parameter."

A Stored Procedure (SP) is a saved SQL function. Instead of writing the same INSERT logic every time, you call:

```sql
EXEC DimDate_Load @DateValue = '2013-01-01';
```

And it calculates Year, Month, Quarter, DayOfWeek, etc. automatically from that one date.

## Understanding the class SP (Week 7 PDF p.45)

![p.45](../req1-schema/images/week7-p45.png)

The class wrote `DimDate_Load` — let's understand each line:

```sql
CREATE OR ALTER PROCEDURE dbo.DimDate_Load
    @DateValue DATE            -- Input: one date (e.g. '2013-01-01')
AS
BEGIN
    INSERT INTO dbo.DimDate
    SELECT
        -- DateKey: Smart Key = YYYYMMDD integer
        -- e.g. 2013-01-01 → 2013*10000 + 1*100 + 1 = 20130101
        CAST(YEAR(@DateValue) * 10000 + MONTH(@DateValue) * 100 + DAY(@DateValue) AS INT),

        @DateValue,                              -- DateValue: the date itself
        YEAR(@DateValue),                        -- CYear: 2013
        MONTH(@DateValue),                       -- CMonth: 1
        DAY(@DateValue),                         -- DayNo: 1
        DATEPART(qq, @DateValue),                -- CQtr: 1 (quarter)
        DATEADD(DAY, 1, EOMONTH(@DateValue, -1)),-- StartOfMonth: first day of month
        EOMONTH(@DateValue),                     -- EndOfMonth: last day of month
        DATENAME(mm, @DateValue),                -- MonthName: 'January'
        DATENAME(dw, @DateValue);                -- DayOfWeekName: 'Tuesday'
END;
GO
```

Key T-SQL functions used:

- `YEAR()`, `MONTH()`, `DAY()` — extract parts of a date
- `DATEPART(qq, ...)` — get quarter number (1-4)
- `EOMONTH(date)` — last day of that month. `EOMONTH(date, -1)` — last day of previous month
- `DATEADD(DAY, 1, ...)` — add 1 day
- `DATENAME(mm, ...)` — month name as text. `DATENAME(dw, ...)` — day of week as text

## WHILE Loop — loading 5 years

One SP call = one row. We need ~1,827 rows (5 years of dates).
A WHILE loop calls the SP for every day from 2012-01-01 to 2016-12-31:

```sql
DECLARE @StartDate DATE = '2012-01-01';
DECLARE @EndDate   DATE = '2016-12-31';
DECLARE @Date      DATE = @StartDate;

WHILE @Date <= @EndDate
BEGIN
    EXEC dbo.DimDate_Load @DateValue = @Date;
    SET @Date = DATEADD(DAY, 1, @Date);  -- move to next day
END;
GO
```

Each iteration: call SP → insert 1 row → move date forward 1 day → repeat until EndDate.

## Verify

```sql
-- Total rows (5 years: 2012 leap year + 2013-2015 + 2016 leap year)
SELECT COUNT(*) AS TotalRows FROM dbo.DimDate;
-- Expected: 1,827

-- Spot check: January 2013 should have 31 rows
SELECT * FROM dbo.DimDate WHERE CYear = 2013 AND CMonth = 1;

-- Verify Smart Key format
SELECT DateKey, DateValue, DayOfWeekName FROM dbo.DimDate WHERE DateKey = 20130101;
-- Expected: 20130101 | 2013-01-01 | Tuesday
```
