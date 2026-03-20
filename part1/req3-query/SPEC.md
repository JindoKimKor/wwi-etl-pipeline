# Req 3: Compelling Warehouse Query (2 marks)

> **BI Concept: OLAP Query / Business Analytics**
> - The reason Star Schema exists — "We built this structure so we can answer these questions"
> - OLAP = Multidimensional analysis. Combine Dims to slice Facts from multiple angles
> - "Predict the Future" = Find patterns in historical data to inform business decisions

## What You Can Demonstrate When Complete

e.g., "In Q1 2013, Supplier X's products in California saw a 30% revenue increase vs. the previous quarter → recommend expanding the contract with that supplier" — derive this kind of business insight from query results

## PDF Requirements

- A query that uses Customer, City, Salespeople, Products, Suppliers, and Dates for Order facts
- Business scenario and fields are free choice
- **Grading:** A working query = base marks, additional marks if the **"Predict the Future"** perspective is compelling

> "What would an expert business person like to learn that would help them to 'Predict the Future' & then USE that information to make their business better!"

## Query Structure Guide

JOIN all Dims + Fact:

```sql
SELECT
    c.CustomerName,
    l.CityName,
    sp.SalespersonName,
    p.ProductName,
    s.FullName AS SupplierName,
    d.CYear, d.CQtr, d.MonthName,
    SUM(f.Quantity) AS TotalQuantity,
    SUM(f.TotalAfterTax) AS TotalRevenue
FROM dbo.FactSales f
JOIN dbo.DimCustomers c    ON f.CustomerKey    = c.CustomerKey
JOIN dbo.DimLocation l     ON f.LocationKey    = l.LocationKey
JOIN dbo.DimSalesPeople sp ON f.SalespersonKey = sp.SalespersonKey
JOIN dbo.DimProducts p     ON f.ProductKey     = p.ProductKey
JOIN dbo.DimSuppliers s    ON f.SupplierKey    = s.SupplierKey
JOIN dbo.DimDate d         ON f.DateKey        = d.DateKey
GROUP BY ...
ORDER BY ...;
```

## "Predict the Future" Ideas

| Scenario | Query Idea |
|----------|-----------|
| Supplier performance comparison | Daily avg revenue by supplier over time → which supplier's products are growing? |
| Regional preferences | Best-selling product category by city → region-specific marketing |
| Salesperson efficiency | Revenue per customer by salesperson → who is most efficient? |
| Time trends | Daily revenue trends → discover seasonal patterns → forecast inventory |

## Work Items

- [ ] Write a SELECT query that JOINs all Dims + Fact
- [ ] Choose a "Predict the Future" business scenario & write the query

## Notes

- **Dependency:** Must run after Req 7 (data load) for results to appear
- The query itself can be written in advance, but **testing requires Req 7 completion**
