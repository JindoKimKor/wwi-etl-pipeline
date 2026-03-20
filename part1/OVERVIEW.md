# Part 1: Star Schema (10 marks)

Build a Star Schema-based Data Warehouse + load date dimension + analytical query.

## Requirements Overview

| Req | Description | Marks | Assigned to |
|-----|-------------|-------|-------------|
| [Req 1](req1-schema/) | Dimensional Model tables (PKs, FKs, Indexes) | 5 | Member A |
| [Req 2](req2-dimdate/) | Date dimension & Stored Procedure to load it | 3 | Member A |
| [Req 3](req3-query/) | Compelling Warehouse Query ("Predict the Future") | 2 | All members |

## Dependencies

```
Phase 0 (Environment Setup)
  └→ Req 1 (Table creation) ★ Full blocker — B,C cannot start until this is done
       └→ Req 2 (DimDate load)
            └→ ... After Req 7 → Req 3 (Analytical query)
```

## Course Materials

- **Week 7 PDF:** Star Schema, Dimensional Modelling, Fact/Dim table structures
  - `resources/course-material/PROG3240_week7_dimensional-model-part1.pdf`
- **Week 7 class notes (Logbook):** CREATE TABLE, INDEX, DimDate_Load SP code
  - `logbook/2026-02-26/log.md`

## Deliverable

`Part1_Group11.sql` — Req 1 + 2 + 3 combined into a single file

```sql
/* REQUIREMENT 1 */
-- CREATE TABLE, ALTER TABLE, CREATE INDEX ...

/* REQUIREMENT 2 */
-- DimDate_Load SP + WHILE Loop

/* REQUIREMENT 3 */
-- Compelling Query
```
