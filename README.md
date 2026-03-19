# WWI ETL Pipeline — PROG3240 Assignment 3

**Course:** PROG3240 Business Intelligence (Winter 2026)
**Assignment:** Final Project Assignment 3 (30%)
**Due:** Sunday, Apr 5th @11:59 PM
**Group:** 11

## Overview

WideWorldImporters (OLTP) → WWI_DM (Star Schema Data Mart) ETL Pipeline

```mermaid
flowchart LR
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
        E["Extract"]
        T["Transform"]
        L["Load"]
        E --> T --> L
    end

    subgraph DW["WWI_DM (Star Schema)"]
        direction TB
        FS[FactSales]
        DC[DimCustomers] ---|FK| FS
        DP[DimProducts] ---|FK| FS
        DS[DimSalesPeople] ---|FK| FS
        DL[DimLocation] ---|FK| FS
        DD[DimDate] ---|FK| FS
        DSU["DimSuppliers ★ NEW"] ---|FK| FS
    end

    SOURCE --> E
    L --> DW

    style SOURCE fill:#fff3e0,stroke:#e65100
    style ETL fill:#e3f2fd,stroke:#1565c0
    style DW fill:#e8f5e9,stroke:#2e7d32
    style DSU fill:#ffcdd2,stroke:#c62828
```

## Setup (Each team member)

1. Download WideWorldImporters `.bak` from [Microsoft SQL Server Samples](https://github.com/microsoft/sql-server-samples/tree/master/samples/databases/wide-world-importers)
2. Restore in SSMS: Databases → Restore Database → Device → select `.bak`
3. Verify: `USE WideWorldImporters; SELECT COUNT(*) FROM Sales.Orders;`
4. Create target DB: `CREATE DATABASE WWI_DM;`

## Project Structure

```
wwi-etl-pipeline/
├── part1/                       # Part 1: Star Schema (10 marks)
│   ├── req1-schema/             # Req 1: Dimensional Model tables (5)
│   ├── req2-dimdate/            # Req 2: DimDate SP + load (3)
│   └── req3-query/              # Req 3: Compelling query (2)
│
├── part2/                       # Part 2: ETL Pipeline (20 marks)
│   ├── req4-extract/            # Req 4: Extract SPs + Python (6)
│   ├── req5-transform/          # Req 5: Transform SPs + SSIS (8)
│   ├── req6-load/               # Req 6: Load SPs (4)
│   └── req7-execute/            # Req 7: Execute 4 days + query (2)
│
├── submission/                  # Final submission files
│   ├── Part1_Group11.sql
│   ├── Part2_Group11.sql
│   ├── Part2_Group11.py
│   └── Part2_Group11.dtsx
│
└── docs/                        # Notes & references
```

## Dependency Flow

```mermaid
flowchart TD
    P0["Phase 0: Environment Setup"]
    R1["Req 1: Star Schema Tables"]
    R2["Req 2: DimDate Load"]
    R4["Req 4: Extract"]
    R5["Req 5: Transform"]
    R6["Req 6: Load"]
    R7["Req 7: Execute & Verify"]
    R3["Req 3: Compelling Query"]

    P0 --> R1
    R1 --> R2
    R1 --> R4
    R4 --> R5
    R5 --> R6
    R2 --> R7
    R6 --> R7
    R7 --> R3

    style R1 fill:#bbdefb,stroke:#1976d2
    style R2 fill:#bbdefb,stroke:#1976d2
    style R4 fill:#fff9c4,stroke:#f9a825
    style R5 fill:#ffccbc,stroke:#e64a19
    style R6 fill:#bbdefb,stroke:#1976d2
    style R7 fill:#d1c4e9,stroke:#7b1fa2
    style R3 fill:#c8e6c9,stroke:#388e3c
```

## Submission

- `Part1_Group11.sql` — DDL + DimDate + Query
- `Part2_Group11.sql` — All ETL stored procedures
- `Part2_Group11.py` — Python extract/transform (min 1)
- `Part2_Group11.dtsx` — SSIS package (min 1)

**All scripts must execute without errors against WideWorldImporters + WWI_DM.**
