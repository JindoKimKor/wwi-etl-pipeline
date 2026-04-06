# ============================================================
# Part 2: ETL Pipeline — Samuel
# Group 11 | PROG3240 Winter 2026
# ============================================================
# Requirement 4: Extract (Python) — Customers + Suppliers
# Requirement 5: Transform (Python) — Customers (SCD2) + Suppliers (SCD2)
#
# Run: python Part2_Group11.py
# Requires: pyodbc, ODBC Driver 18 for SQL Server
# Connections: localhost:1433, SA auth
# ============================================================

import pyodbc
from datetime import date

# ============================================================
# CONNECTION
# ============================================================

# Original connection (Samuel — Mac/Docker with SA auth):
# CONN_STR = (
#     "DRIVER={ODBC Driver 18 for SQL Server};"
#     "SERVER=localhost,1433;"
#     "UID=SA;"
#     "PWD=Admin1234!;"
#     "TrustServerCertificate=yes;"
# )
# Changed to Windows Auth + ODBC 17 for consistency with .sql and .dtsx files.
# Submission requirement: "Your script must execute without error" — SA auth may fail on grading environment.
CONN_STR = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=localhost;"
    "Trusted_Connection=yes;"
)

def get_source():
    """Connect to WideWorldImporters (source OLTP)."""
    return pyodbc.connect(CONN_STR + "DATABASE=WideWorldImporters;")

def get_target():
    """Connect to WWI_DM (target data mart)."""
    return pyodbc.connect(CONN_STR + "DATABASE=WWI_DM;")


# ============================================================
# REQUIREMENT 4 — EXTRACT
# ============================================================

def customers_extract():
    """
    Extract: Customers_Stage
    Joins: Customers + CustomerCategories + Cities (delivery + postal)
           + StateProvinces + Countries
    Flattens 8 source tables into 1 flat stage table.
    """
    print("  [Extract] Customers_Stage ...", end=" ")

    sql_source = """
        WITH CityChain AS (
            SELECT
                ci.CityID,
                ci.CityName,
                sp.StateProvinceCode  AS StateProvCode,
                sp.StateProvinceName  AS StateProvName,
                co.CountryName,
                co.FormalName         AS CountryFormalName
            FROM Application.Cities          ci
            JOIN Application.StateProvinces  sp ON ci.StateProvinceID   = sp.StateProvinceID
            JOIN Application.Countries       co ON sp.CountryID         = co.CountryID
        )
        SELECT
            c.CustomerName,
            cc.CustomerCategoryName,
            dc.CityName              AS DeliveryCityName,
            dc.StateProvCode         AS DeliveryStateProvCode,
            dc.CountryName           AS DeliveryCountryName,
            pc.CityName              AS PostalCityName,
            pc.StateProvCode         AS PostalStateProvCode,
            pc.CountryName           AS PostalCountryName
        FROM Sales.Customers             c
        JOIN Sales.CustomerCategories    cc ON c.CustomerCategoryID    = cc.CustomerCategoryID
        JOIN CityChain                   dc ON c.DeliveryCityID        = dc.CityID
        JOIN CityChain                   pc ON c.PostalCityID          = pc.CityID
    """

    src = get_source()
    tgt = get_target()
    try:
        rows = src.cursor().execute(sql_source).fetchall()

        cur = tgt.cursor()
        cur.execute("TRUNCATE TABLE dbo.Customers_Stage")
        cur.executemany(
            """INSERT INTO dbo.Customers_Stage
               (CustomerName, CustomerCategoryName,
                DeliveryCityName, DeliveryStateProvCode, DeliveryCountryName,
                PostalCityName,   PostalStateProvCode,   PostalCountryName)
               VALUES (?,?,?,?,?,?,?,?)""",
            rows
        )
        tgt.commit()

        if len(rows) == 0:
            raise Exception("Customers_Extract: no rows extracted from source.")
        print(f"{len(rows)} rows loaded.")
    finally:
        src.close()
        tgt.close()


def suppliers_extract():
    """
    Extract: Suppliers_Stage
    Joins: Suppliers + SupplierCategories
    Flattens 2 source tables into 1 flat stage table.
    """
    print("  [Extract] Suppliers_Stage ...", end=" ")

    sql_source = """
        SELECT
            s.SupplierName       AS FullName,
            s.PhoneNumber,
            s.FaxNumber,
            s.WebsiteURL,
            sc.SupplierCategoryName
        FROM Purchasing.Suppliers           s
        JOIN Purchasing.SupplierCategories  sc ON s.SupplierCategoryID = sc.SupplierCategoryID
    """

    src = get_source()
    tgt = get_target()
    try:
        rows = src.cursor().execute(sql_source).fetchall()

        cur = tgt.cursor()
        cur.execute("TRUNCATE TABLE dbo.Suppliers_Stage")
        cur.executemany(
            """INSERT INTO dbo.Suppliers_Stage
               (FullName, PhoneNumber, FaxNumber, WebsiteURL, SupplierCategoryName)
               VALUES (?,?,?,?,?)""",
            rows
        )
        tgt.commit()

        if len(rows) == 0:
            raise Exception("Suppliers_Extract: no rows extracted from source.")
        print(f"{len(rows)} rows loaded.")
    finally:
        src.close()
        tgt.close()


# ============================================================
# REQUIREMENT 5 — TRANSFORM
# ============================================================

def customers_transform():
    """
    Transform: Customers_Stage -> Customers_Preload (SCD Type 2)

    4 cases:
      a) Match, no change        -> add as-is (keep existing key)
      b) Match, attribute change -> new key (Sequence) + expire old in Preload
      c) New record              -> new key (Sequence), StartDate = today
      d) In DW but not in Stage  -> expire in Preload (set EndDate = today)
    """
    print("  [Transform] Customers_Preload (SCD2) ...", end=" ")

    tgt = get_target()
    try:
        cur = tgt.cursor()
        today = date.today()

        # Load stage records (business key = CustomerName)
        stage_rows = cur.execute(
            """SELECT CustomerName, CustomerCategoryName,
                      DeliveryCityName, DeliveryStateProvCode, DeliveryCountryName,
                      PostalCityName,   PostalStateProvCode,   PostalCountryName
               FROM dbo.Customers_Stage"""
        ).fetchall()

        if not stage_rows:
            raise Exception("Customers_Transform: Customers_Stage is empty.")

        # Build dict keyed on CustomerName for fast lookup
        stage_dict = {r[0]: r for r in stage_rows}

        # Load current active DW records (EndDate IS NULL = current)
        dw_rows = cur.execute(
            """SELECT CustomerKey, CustomerName, CustomerCategoryName,
                      DeliveryCityName, DeliveryStateProvCode, DeliveryCountryName,
                      PostalCityName,   PostalStateProvCode,   PostalCountryName,
                      StartDate, EndDate
               FROM dbo.DimCustomers
               WHERE EndDate IS NULL"""
        ).fetchall()

        dw_dict = {r[1]: r for r in dw_rows}

        # Truncate PreLoad for fresh build
        cur.execute("TRUNCATE TABLE dbo.Customers_Preload")

        preload_rows = []

        # Cases a, b, c — iterate over stage
        for name, s in stage_dict.items():
            if name in dw_dict:
                dw = dw_dict[name]
                # Compare non-key attributes (indices 2-8)
                same = (
                    s[1] == dw[2] and  # CustomerCategoryName
                    s[2] == dw[3] and  # DeliveryCityName
                    s[3] == dw[4] and  # DeliveryStateProvCode
                    s[4] == dw[5] and  # DeliveryCountryName
                    s[5] == dw[6] and  # PostalCityName
                    s[6] == dw[7] and  # PostalStateProvCode
                    s[7] == dw[8]      # PostalCountryName
                )
                if same:
                    # Case a: no change — keep existing key and dates
                    preload_rows.append((
                        dw[0],   # CustomerKey
                        s[0], s[1], s[2], s[3], s[4], s[5], s[6], s[7],
                        dw[9],   # StartDate unchanged
                        None     # EndDate stays NULL
                    ))
                else:
                    # Case b: changed — expire old, create new
                    # Expire old record in PreLoad
                    preload_rows.append((
                        dw[0],
                        dw[1], dw[2], dw[3], dw[4], dw[5], dw[6], dw[7], dw[8],
                        dw[9],   # original StartDate
                        today    # EndDate = today
                    ))
                    # New record with next sequence value
                    new_key = cur.execute(
                        "SELECT NEXT VALUE FOR dbo.CustomerKey"
                    ).fetchval()
                    preload_rows.append((
                        new_key,
                        s[0], s[1], s[2], s[3], s[4], s[5], s[6], s[7],
                        today,   # StartDate = today
                        None
                    ))
            else:
                # Case c: new record
                new_key = cur.execute(
                    "SELECT NEXT VALUE FOR dbo.CustomerKey"
                ).fetchval()
                preload_rows.append((
                    new_key,
                    s[0], s[1], s[2], s[3], s[4], s[5], s[6], s[7],
                    today,
                    None
                ))

        # Case d: in DW but missing from stage — expire
        for name, dw in dw_dict.items():
            if name not in stage_dict:
                preload_rows.append((
                    dw[0],
                    dw[1], dw[2], dw[3], dw[4], dw[5], dw[6], dw[7], dw[8],
                    dw[9],
                    today    # ExpireDate
                ))

        cur.executemany(
            """INSERT INTO dbo.Customers_Preload
               (CustomerKey, CustomerName, CustomerCategoryName,
                DeliveryCityName, DeliveryStateProvCode, DeliveryCountryName,
                PostalCityName,   PostalStateProvCode,   PostalCountryName,
                StartDate, EndDate)
               VALUES (?,?,?,?,?,?,?,?,?,?,?)""",
            preload_rows
        )
        tgt.commit()
        print(f"{len(preload_rows)} rows in PreLoad.")
    finally:
        tgt.close()


def suppliers_transform():
    """
    Transform: Suppliers_Stage -> Suppliers_Preload (SCD Type 2)

    Same 4-case logic as Customers (business key = FullName).
    """
    print("  [Transform] Suppliers_Preload (SCD2) ...", end=" ")

    tgt = get_target()
    try:
        cur = tgt.cursor()
        today = date.today()

        stage_rows = cur.execute(
            """SELECT FullName, PhoneNumber, FaxNumber, WebsiteURL, SupplierCategoryName
               FROM dbo.Suppliers_Stage"""
        ).fetchall()

        if not stage_rows:
            raise Exception("Suppliers_Transform: Suppliers_Stage is empty.")

        stage_dict = {r[0]: r for r in stage_rows}

        dw_rows = cur.execute(
            """SELECT SupplierKey, FullName, PhoneNumber, FaxNumber,
                      WebsiteURL, SupplierCategoryName, StartDate, EndDate
               FROM dbo.DimSuppliers
               WHERE EndDate IS NULL"""
        ).fetchall()

        dw_dict = {r[1]: r for r in dw_rows}

        cur.execute("TRUNCATE TABLE dbo.Suppliers_Preload")

        preload_rows = []

        for name, s in stage_dict.items():
            if name in dw_dict:
                dw = dw_dict[name]
                same = (
                    s[1] == dw[2] and  # PhoneNumber
                    s[2] == dw[3] and  # FaxNumber
                    s[3] == dw[4] and  # WebsiteURL
                    s[4] == dw[5]      # SupplierCategoryName
                )
                if same:
                    # Case a
                    preload_rows.append((
                        dw[0],
                        s[0], s[1], s[2], s[3], s[4],
                        dw[6], None
                    ))
                else:
                    # Case b — expire old
                    preload_rows.append((
                        dw[0],
                        dw[1], dw[2], dw[3], dw[4], dw[5],
                        dw[6], today
                    ))
                    # New record
                    new_key = cur.execute(
                        "SELECT NEXT VALUE FOR dbo.SupplierKey"
                    ).fetchval()
                    preload_rows.append((
                        new_key,
                        s[0], s[1], s[2], s[3], s[4],
                        today, None
                    ))
            else:
                # Case c
                new_key = cur.execute(
                    "SELECT NEXT VALUE FOR dbo.SupplierKey"
                ).fetchval()
                preload_rows.append((
                    new_key,
                    s[0], s[1], s[2], s[3], s[4],
                    today, None
                ))

        # Case d
        for name, dw in dw_dict.items():
            if name not in stage_dict:
                preload_rows.append((
                    dw[0],
                    dw[1], dw[2], dw[3], dw[4], dw[5],
                    dw[6], today
                ))

        cur.executemany(
            """INSERT INTO dbo.Suppliers_Preload
               (SupplierKey, FullName, PhoneNumber, FaxNumber,
                WebsiteURL, SupplierCategoryName, StartDate, EndDate)
               VALUES (?,?,?,?,?,?,?,?)""",
            preload_rows
        )
        tgt.commit()
        print(f"{len(preload_rows)} rows in PreLoad.")
    finally:
        tgt.close()


# ============================================================
# MAIN
# ============================================================

if __name__ == "__main__":
    print("=" * 50)
    print("Part 2 ETL — Python (Group 11)")
    print("=" * 50)

    print("\n--- REQUIREMENT 4: Extract ---")
    customers_extract()
    suppliers_extract()

    print("\n--- REQUIREMENT 5: Transform ---")
    customers_transform()
    suppliers_transform()

    print("\nDone.")
