# WWI ETL Pipeline — PROG3240 Assignment 3

**Course:** PROG3240 Business Intelligence (Winter 2026)
**Assignment:** Final Project Assignment 3 (30%)
**Due:** Sunday, Apr 5th @11:59 PM
**Group:** 11

---

## Goal

An automated pipeline that extracts data from WideWorldImporters (store operations DB) → loads it into an analytical Star Schema DB (WWI_DM)

```mermaid
flowchart TB
    subgraph SOURCE["WideWorldImporters (OLTP)"]
        direction TB
        O[Orders]
        CU[Customers]
        PR[Products]
        SU[Suppliers]
        PE[People]
        CI[Cities]
    end

    subgraph ETL["ETL Pipeline"]
        direction TB
        E["Extract<br>(T-SQL / Python / SSIS)"]
        T["Transform<br>(SCD Type 1 & 2)"]
        L["Load<br>(Transaction Safe)"]
        E --> T --> L
    end

    subgraph DW["WWI_DM (Star Schema)"]
        direction TB
        DC[DimCustomers]
        DP[DimProducts]
        DS[DimSalesPeople]
        DL[DimLocation]
        DD[DimDate]
        DSU["DimSuppliers ★ NEW"]
        FS[FactSales]

        DC ---|FK| FS
        DP ---|FK| FS
        DS ---|FK| FS
        DL ---|FK| FS
        DD ---|FK| FS
        DSU ---|FK| FS
    end

    SOURCE --> E
    L --> DW

    style SOURCE fill:#e65100,stroke:#bf360c,color:#fff
    style ETL fill:#1565c0,stroke:#0d47a1,color:#fff
    style DW fill:#2e7d32,stroke:#1b5e20,color:#fff
    style DSU fill:#c62828,stroke:#b71c1c,color:#fff
    style FS fill:#1b5e20,stroke:#0a3d0a,color:#fff
```

```
Store Ledger (WideWorldImporters)    →    Business Analysis Report (WWI_DM)
  "Jan 1, John ordered 3 red pens"          "Which products sell best?"
  "Jan 2, Jane ordered 5 blue balls"        "Which cities buy the most?"
                                             "Which supplier's products are popular?"
```

- **Extract** = Pull needed information from the ledger
- **Transform** = Reshape into analysis-friendly format (unify names, map keys, track change history)
- **Load** = Insert into the analysis report DB

---

## Setup (Each team member)

1. Download WideWorldImporters `.bak` from [Microsoft SQL Server Samples](https://github.com/microsoft/sql-server-samples/tree/master/samples/databases/wide-world-importers)
2. Restore in SSMS: Databases → Restore Database → Device → select `.bak`
3. Verify: `USE WideWorldImporters; SELECT COUNT(*) FROM Sales.Orders;`
4. Create target DB: `CREATE DATABASE WWI_DM;`

> Detail: [part0-setup/SETUP-GUIDE.md](part0-setup/SETUP-GUIDE.md)

---

## Project Structure

```
wwi-etl-pipeline/
├── part0-setup/                 # Phase 0: Environment Setup
│   ├── SETUP-GUIDE.md
│   └── setup.sql
│
├── part1/                       # Part 1: Star Schema (10 marks)
│   ├── OVERVIEW.md
│   ├── req1-schema/             # Req 1: Dimensional Model tables (5)
│   │   └── SPEC.md
│   ├── req2-dimdate/            # Req 2: DimDate SP + load (3)
│   │   └── SPEC.md
│   └── req3-query/              # Req 3: Compelling query (2)
│       └── SPEC.md
│
├── part2/                       # Part 2: ETL Pipeline (20 marks)
│   ├── OVERVIEW.md
│   ├── req4-extract/            # Req 4: Extract SPs + Python (6)
│   │   └── SPEC.md
│   ├── req5-transform/          # Req 5: Transform SPs + SSIS (8)
│   │   └── SPEC.md
│   ├── req6-load/               # Req 6: Load SPs (4)
│   │   └── SPEC.md
│   └── req7-execute/            # Req 7: Execute 4 days + query (2)
│       └── SPEC.md
│
├── submission/                  # Final submission files
│   ├── Part1_Group11.sql
│   ├── Part2_Group11.sql
│   ├── Part2_Group11.py
│   └── Part2_Group11.dtsx
│
└── docs/                        # Assignment PDF
```

---

## Requirements

| Phase | SPEC | Description | Marks |
|-------|------|-------------|-------|
| Phase 0 | [SETUP-GUIDE](part0-setup/SETUP-GUIDE.md) | Environment Setup (WWI restore, DB creation) | - |
| **Part 1** | [OVERVIEW](part1/OVERVIEW.md) | **Star Schema Construction** | **10** |
| Req 1 | [SPEC](part1/req1-schema/SPEC.md) | Dimensional Model tables + DimSuppliers | 5 |
| Req 2 | [SPEC](part1/req2-dimdate/SPEC.md) | DimDate SP + WHILE Loop 5 years | 3 |
| Req 3 | [SPEC](part1/req3-query/SPEC.md) | Compelling Query ("Predict the Future") | 2 |
| **Part 2** | [OVERVIEW](part2/OVERVIEW.md) | **ETL Pipeline** | **20** |
| Req 4 | [SPEC](part2/req4-extract/SPEC.md) | Extract (Stage + SP + Python + SSIS) | 6 |
| Req 5 | [SPEC](part2/req5-transform/SPEC.md) | Transform (SCD1/2 + PreLoad + SSIS) | 8 |
| Req 6 | [SPEC](part2/req6-load/SPEC.md) | Load (Transaction + ROLLBACK) | 4 |
| Req 7 | [SPEC](part2/req7-execute/SPEC.md) | Execute 4 days + Verification | 2 |

---

## Team & Dependency

### Distribution

```
        Part 1 (Schema)     Part 2 (ETL Pipeline)
        ┌──────────┐    ┌────────┬────────┬────────┐
Mem A:  │ Req 1,2  │    │ Req 6  │ Req 7  │ Integ. │
        │ Tables + │    │ Load   │ Exec   │ Test   │
        │ DimDate  │    │ SP     │ +Query │        │
        └──────────┘    └────────┴────────┴────────┘
Mem B:                   ┌────────────────┐
                         │ Req 4: Extract │ T-SQL + Python
                         │ 5 Stage SPs    │
                         └────────────────┘
Mem C:                   ┌─────────────────┐
                         │ Req 5: Transform│ T-SQL + SSIS
                         │ SCD1/2 + PreLoad│
                         └─────────────────┘
Req 3 (Query):           → All three together (after data is loaded)
```

### Dependencies & Contracts

Each phase **provides table structures as a contract to the next phase**. Code can be written in parallel, but the contracts (table structures) must be agreed upon first.

```mermaid
flowchart TD
    P0["Phase 0: Environment Setup<br>Each member locally"]
    R1["Req 1: Star Schema<br>Member A — 5 marks"]
    R2["Req 2: DimDate<br>Member A — 3 marks"]
    R4["Req 4: Extract<br>Member B — 6 marks"]
    R5["Req 5: Transform<br>Member C — 8 marks"]
    R6["Req 6: Load<br>Member A — 4 marks"]
    R7["Req 7: Execute<br>All members — 2 marks"]
    R3["Req 3: Query<br>All members — 2 marks"]

    P0 --> R1
    R1 -- "Contract: Dim/Fact structure" --> R2
    R1 -- "Contract: Dim/Fact structure" --> R4
    R4 -- "Contract: Stage table structure" --> R5
    R5 -- "Contract: PreLoad table structure" --> R6
    R2 --> R7
    R6 --> R7
    R7 --> R3

    style P0 fill:#616161,stroke:#424242,color:#fff
    style R1 fill:#1565c0,stroke:#0d47a1,color:#fff
    style R2 fill:#1565c0,stroke:#0d47a1,color:#fff
    style R3 fill:#2e7d32,stroke:#1b5e20,color:#fff
    style R4 fill:#f9a825,stroke:#f57f17,color:#000
    style R5 fill:#e64a19,stroke:#bf360c,color:#fff
    style R6 fill:#1565c0,stroke:#0d47a1,color:#fff
    style R7 fill:#7b1fa2,stroke:#4a148c,color:#fff
```

### Contracts

| Contract | Defined by | Consumed by | Contents | Location |
|----------|-----------|-------------|----------|----------|
| Dim/Fact structure | Member A (Req 1) | All members | Table columns, PK/FK, Index | [req1 SPEC](part1/req1-schema/SPEC.md) |
| Stage structure | Member B (Req 4) | Member C (Req 5) | Stage_* table columns/types | [req4 SPEC](part2/req4-extract/SPEC.md) |
| PreLoad structure | Member C (Req 5) | Member A (Req 6) | PreLoad_* table columns, Sequence | [req5 SPEC](part2/req5-transform/SPEC.md) |

> **Code writing** can be done in parallel once contracts are agreed. **Execution** must follow Req 4 → 5 → 6 sequentially.

**Critical Path:** `Phase 0 → Req 1 → Req 4 → Req 5 → Req 6 → Req 7 → Req 3`

### Timeline
```
Week 1: A completes Req 1,2 → shares DDL with B,C
Week 2: B (Extract), C (Transform) in parallel. A works on Req 6
Week 3: Merge → Integration test → Req 7 + Req 3
```

---

## Submission

- `Part1_Group11.sql` — DDL + DimDate + Query
- `Part2_Group11.sql` — All ETL stored procedures
- `Part2_Group11.py` — Python extract/transform (min 1)
- `Part2_Group11.dtsx` — SSIS package (min 1)

**All scripts must execute without errors against WideWorldImporters + WWI_DM.**

---

## Reference

### Course Materials
- **Req 1, 2:** Week 7 PDF (Star Schema, DimDate_Load)
- **Req 4-6:** Week 10 PDF (T-SQL ETL) + Week 9 PDF (SCD)
- **Python:** Lab 6 (pyodbc)
- **SSIS:** Week 10 lecture

### Videos
- [Install SSIS in Visual Studio: Build Your First ETL Task](https://www.youtube.com/watch?v=oqG0g0W9EuU)
- [Create an ETL package with SSIS! // step-by-step](https://www.youtube.com/watch?v=msCJxaA63IA)
- [SCD Type 2 in SSIS Using Lookup](https://www.youtube.com/watch?v=7uj463csru0)
- [SQL ETL Tutorial for Beginners](https://www.youtube.com/watch?v=uy8-0rX-RV8)
