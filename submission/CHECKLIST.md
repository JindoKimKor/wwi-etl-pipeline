# Submission Checklist

## Files to Submit (4 files, NO ZIP)

| File | Content | Status |
|------|---------|--------|
| [Part1_Group11.sql](Part1_Group11.sql) | Req 1 + 2 + 3 combined | ✅ Done |
| `Part2_Group11.sql` | Req 4 + 5 + 6 + 7 combined | ❌ Not started |
| `Part2_Group11.py` | Python: Req 4 Extract + Req 5 Transform (Member B) | ❌ Not started |
| `Part2_Group11.dtsx` | SSIS: Req 4 Extract + Req 5 Transform (Member C) | ❌ Not started |

## SQL File Format

Each requirement must be clearly separated with comments:

```sql
/* REQUIREMENT 1 */
-- CREATE TABLE, ALTER TABLE, CREATE INDEX ...

/* REQUIREMENT 2 */
-- DimDate_Load SP + WHILE Loop

/* REQUIREMENT 3 */
-- Compelling Query
```

## Pre-Submission Testing

Professor will run the script **top-to-bottom in one go**. He will NOT debug errors.

### Part1_Group11.sql
- [ ] Run against fresh `WWI_DM` database (DROP + CREATE)
- [ ] Req 1 → 2 → 3 executes in order without errors
- [ ] All tables created with correct PK/FK/Index
- [ ] DimDate populated (~1,827 rows)
- [ ] Req 3 query runs (may return 0 rows before Part 2 — that's OK)

### Part2_Group11.sql
- [ ] Execution order: Stage CREATE → Extract SP → PreLoad CREATE → Sequence CREATE → Transform SP → Load SP → Req 7 execution
- [ ] All `CREATE OR ALTER PROCEDURE` (not just `CREATE`) to avoid errors on re-run
- [ ] 4-day ETL loop runs (2013-01-01 ~ 2013-01-04)
- [ ] Req 3 query re-run shows actual data

### Part2_Group11.py
- [ ] Runs independently (`python Part2_Group11.py`)
- [ ] Connection string uses `localhost` + Windows Authentication
- [ ] Stage/PreLoad table names match the `.sql` file
- [ ] `pyodbc` is the only external dependency

### Part2_Group11.dtsx
- [ ] Opens in Visual Studio without errors
- [ ] Connection Manager points to `localhost`
- [ ] Data Flow Task executes successfully

## Common Mistakes to Avoid

- **DO NOT** use `CREATE PROCEDURE` without `OR ALTER` — fails on second run
- **DO NOT** hardcode server names (use `localhost` or `.`)
- **DO NOT** forget `GO` between batches (CREATE PROCEDURE needs its own batch)
- **DO NOT** submit compressed/zipped files
- **DO NOT** include `DROP DATABASE` in submission scripts
- **DO** comment out any code that generates errors (partial marks > 0 marks)
- **DO** test on a clean WWI_DM + WideWorldImporters from scratch

## Final Verification (Full End-to-End)

```sql
-- 1. Start fresh
DROP DATABASE IF EXISTS WWI_DM;
CREATE DATABASE WWI_DM;
GO

-- 2. Run Part1_Group11.sql → should complete without errors
-- 3. Run Part2_Group11.sql → should complete without errors
-- 4. Run Part2_Group11.py  → should complete without errors
-- 5. Open Part2_Group11.dtsx in VS → execute → should succeed

-- 6. Verify
USE WWI_DM;
SELECT COUNT(*) FROM DimDate;        -- ~1,827
SELECT COUNT(*) FROM DimCustomers;   -- > 0
SELECT COUNT(*) FROM DimSuppliers;   -- > 0
SELECT COUNT(*) FROM FactSales;      -- > 0 (4 days of data)
```
