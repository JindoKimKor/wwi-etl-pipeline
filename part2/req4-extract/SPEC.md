# Req 4: Extract (6 marks)

## Contract: Stage Table Structure (this Req defines → Req 5 consumes)

The Stage tables created in this Req become the **input for Req 5 (Transform)**. Member C needs to know the column names/types of the Stage tables to write Transform SPs.

| Stage Table | Consumer | Key Columns (needs agreement) |
|-------------|----------|-------------------------------|
| Stage_Customers | Transform_DimCustomers (SCD1) | CustomerID, CustomerName, City, Province, Country, ... |
| Stage_Products | Transform_DimProducts (SCD1) | StockItemID, StockItemName, Colour, UnitPrice, ... |
| Stage_Salespeople | Transform_DimSalesPeople (SCD1) | PersonID, FullName, ... |
| Stage_Orders | Transform_FactSales | OrderID, OrderDate, CustomerID, SalespersonID, StockItemID, Quantity, ... |
| Stage_Suppliers | Transform_DimSuppliers (SCD2) | SupplierID, SupplierName, PhoneNumber, FaxNumber, WebsiteURL, CategoryName, ... |

> **Note:** Stage columns are in denormalized form from the JOIN results of source tables. Finalize and share this structure before starting Req 5.

---

> **BI/Data Pipeline Concepts: The "E" in ETL — Extraction**
> - The source OLTP DB is normalized (tables are split apart). To get customer info, you need to JOIN Customers + Cities + StateProvinces + Countries
> - **Stage Table** = An intermediate table that temporarily holds data extracted from the source. Follows the principle of "work on a copy without touching the source"
> - Why not load directly and instead go through Stage? → Minimize load on the source DB + separate transformation work + source stays safe on failure
> - **Python Extract** = Connect to SQL Server via pyodbc → Execute query → INSERT into Stage table (programmatic approach)
> - **SSIS Extract** = Drag-and-drop Source → Destination connection in Visual Studio (GUI approach)

## Expected Output

```sql
EXEC Extract_Customers;
SELECT TOP 10 * FROM Stage_Customers;
-- → Customer data from WideWorldImporters is JOINed and shown in a denormalized form in a single table
```

## PDF Requirements

5 Stage tables + an Extract Stored Procedure for each:

| # | Extract Target | Source Tables (JOIN) | Method |
|---|----------------|---------------------|--------|
| 1 | Customers | `Sales.Customers` + `Sales.CustomerCategories` + `Application.Cities` + `Application.StateProvinces` + `Application.Countries` | T-SQL |
| 2 | Products | `Warehouse.StockItems` + `Warehouse.Colors` | T-SQL |
| 3 | Salespeople | `Application.People` (WHERE `IsSalesperson = 1`) | T-SQL |
| 4 | Orders | `Sales.Orders` + `Sales.OrderLines` + `Sales.Customers` + `Application.People` (`@OrderDate` parameter) | T-SQL |
| 5 | Suppliers | `Purchasing.Suppliers` + `Purchasing.SupplierCategories` | T-SQL |

**At least 1 must be done in Python, and 1 in SSIS!**

> **Test:** After executing each Extract SP, verify data in Stage tables. Use `'2013-01-01'` for Orders.

## Python Extract Pattern (pyodbc)

```python
import pyodbc

connection_string = (
    r"DRIVER={ODBC Driver 17 for SQL Server};"
    r"SERVER=localhost;"
    r"DATABASE=WideWorldImporters;"
    r"Trusted_Connection=yes;"
)

conn = pyodbc.connect(connection_string)
cursor = conn.cursor()

# Read data from Source
cursor.execute("""
    SELECT c.CustomerID, c.CustomerName, ...
    FROM Sales.Customers c
    JOIN Sales.CustomerCategories cc ON c.CustomerCategoryID = cc.CustomerCategoryID
    JOIN Application.Cities ci ON c.DeliveryCityID = ci.CityID
    ...
""")
rows = cursor.fetchall()

# INSERT into Stage (WWI_DM connection)
conn_dm = pyodbc.connect(
    r"DRIVER={ODBC Driver 17 for SQL Server};"
    r"SERVER=localhost;"
    r"DATABASE=WWI_DM;"
    r"Trusted_Connection=yes;"
)
cursor_dm = conn_dm.cursor()
cursor_dm.execute("TRUNCATE TABLE Stage_Customers;")
for row in rows:
    cursor_dm.execute("INSERT INTO Stage_Customers VALUES (?, ?, ...)", row)
conn_dm.commit()
```

## SSIS Extract Guide

1. VS → Integration Services Project → Data Flow Task
2. **OLE DB Source:** WideWorldImporters connection → JOIN query as SQL Command
3. **OLE DB Destination:** WWI_DM connection → Stage table
4. Connection Manager: `Microsoft OLE DB Driver 19 for SQL Server` + Trust Server Certificate

## Tasks

- [ ] CREATE TABLE for 5 Stage tables
- [ ] Write Extract SP: Customers
- [ ] Write Extract SP: Products
- [ ] Write Extract SP: Salespeople
- [ ] Write Extract SP: Orders (date parameter)
- [ ] Write Extract SP: Suppliers
- [ ] Convert 1 to Python (using pyodbc)
- [ ] Convert 1 to SSIS package
- [ ] Test execution for each (use '2013-01-01' for Orders)

## References

- **Week 10 PDF:** `resources/course-material/PROG3240_week10_etl-using-t-sql-and-ssis.pdf`
  - Extract SP patterns, Stage table structure
- **Lab 6 Notebook:** `resources/labs/lab-6/MSSQL_Connect.ipynb`
  - pyodbc connection, query execution, INSERT patterns
- **Lab 6 Review:** `resources/labs/lab-6/lab-6-review.md`
  - pyodbc workflow summary
- **Video:** [SQL ETL Tutorial for Beginners](https://www.youtube.com/watch?v=uy8-0rX-RV8)
- **Video:** [Create an ETL package with SSIS!](https://www.youtube.com/watch?v=msCJxaA63IA)
