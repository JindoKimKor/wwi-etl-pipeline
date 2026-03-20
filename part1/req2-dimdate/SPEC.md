# Req 2: Date Dimension & Stored Procedure (3 marks)

> **BI Concepts: Date Dimension (SCD Type 0)**
> - The date dimension is an "unchanging truth" — January 1, 2013 is forever a Tuesday and Q1
> - The time axis for all analysis. This is why "monthly sales trends", "quarterly comparisons", etc. are possible
> - Stored Procedure = A reusable SQL function. Pass in one date and it automatically calculates Year, Month, Quarter, etc.

## Expected Output

```sql
SELECT * FROM DimDate WHERE CYear = 2013 AND CMonth = 1;
-- → Each of January's 31 days as one row, with all analysis attributes filled (day of week, quarter, end of month, etc.)
SELECT COUNT(*) FROM DimDate;
-- → ~1,827 total rows (5 years of calendar)
```

## PDF Requirements

- Create `DimDate_Load` Stored Procedure (1 parameter: DateValue)
- INSERT **5 years** of dates using WHILE Loop (2012-01-01 ~ 2016-12-31)

## DimDate Table (already created in Req 1)

```sql
CREATE TABLE dbo.DimDate (
    DateKey       INT          NOT NULL,
    DateValue     DATE         NOT NULL,
    CYear         SMALLINT     NOT NULL,
    CMonth        TINYINT      NOT NULL,
    DayNo         TINYINT      NOT NULL,
    CQtr          TINYINT      NOT NULL,
    StartOfMonth  DATE         NOT NULL,
    EndOfMonth    DATE         NOT NULL,
    MonthName     VARCHAR(9)   NOT NULL,
    DayOfWeekName VARCHAR(9)   NOT NULL,
    CONSTRAINT PK_DimDate PRIMARY KEY (DateKey)
);
```

## DimDate_Load Stored Procedure (class code)

```sql
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
```

## WHILE Loop (load 5 years)

```sql
DECLARE @StartDate DATE = '2012-01-01';
DECLARE @EndDate   DATE = '2016-12-31';
DECLARE @Date      DATE = @StartDate;

WHILE @Date <= @EndDate
BEGIN
    EXEC dbo.DimDate_Load @DateValue = @Date;
    SET @Date = DATEADD(DAY, 1, @Date);
END;
GO

-- Verify
SELECT COUNT(*) AS TotalRows FROM dbo.DimDate;
-- Expected: 1,827 rows (5 years = 365*4 + 366*1 + partial)
```

## Tasks

- [ ] Write DimDate_Load procedure (based on above code)
- [ ] INSERT from 2012-01-01 to 2016-12-31 using WHILE Loop
- [ ] Run & verify (`SELECT COUNT(*) FROM DimDate`)

## References

- **Week 7 PDF:** `resources/course-material/PROG3240_week7_dimensional-model-part1.pdf`
- **Logbook:** `logbook/2026-02-26/log.md` — Original DimDate_Load procedure code
