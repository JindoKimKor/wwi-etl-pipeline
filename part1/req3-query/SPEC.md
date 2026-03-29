# Req 3: Compelling Warehouse Query (2 marks)

---

## What are we doing?

We built a Star Schema (Req 1) and populated DimDate (Req 2).
Now: **what business question does this Star Schema let us answer?**

This is the whole point of building a DW — to ask questions that would be painful in 3NF.

Assignment PDF:
```
Requirement 3 – Create Compelling Warehouse Query (2 Marks)
Write a query that will return Customer, City, Salespeople, Products, suppliers, and dates
for Order facts using this dimensional table… (You decide on the business scenario & fields
to provide the solution for your query… marks will be 3 for a working query, and 3 more for
particularly compelling queries... Think "Predict the Future")
```

> "What would an expert business person like to learn that would help them to 'Predict the Future' & then USE that information to make their business better!"

## Requirements

1. Query must JOIN **all Dims + FactSales** (Customer, City, Salespeople, Products, Suppliers, Dates)
2. Business scenario is our choice
3. "Predict the Future" = find patterns → actionable business insight

## Why Star Schema makes this easy

In 3NF, every analytical question starts with "which tables do I need to JOIN, and in what order?"
```
3NF: "Which supplier's products sell best in Toronto?"
→ Orders + OrderLines + Customers + Cities + StateProvinces + StockItems + Suppliers + ...
→ 8+ tables, complex JOIN order, easy to get wrong
```

In Star Schema, the answer is always the same pattern: **start from FactSales, attach the Dims you need.**
```
Star Schema: same question
→ FactSales + DimLocation + DimSuppliers + DimProducts
→ Always FactSales at center, just pick which Dims to JOIN
```

This is why we built the DW. The Fact table is designed so that any business question is just "FactSales + relevant Dims."

## How to think about it

In Part B notebook, we explored the source data. Now flip it — instead of "what data is available?", ask "what question would a business owner want answered?"

Examples using our Star Schema:
- "Which **supplier's** products generate the most revenue in each **city**?" → expand contracts with top suppliers per region
- "Which **salesperson** sells the most to **corporate** customers?" → assign best salespeople to high-value segments
- "Is revenue **trending up or down** by **product brand** over time?" → stock more of growing brands

Each of these needs multiple Dims joined to FactSales — that's why Star Schema exists.

## Query structure

Every Req 3 query follows this pattern:

```sql
SELECT
    -- Dimensions (the "by what" axes)
    dim1.column,
    dim2.column,
    -- Measures (the "what to calculate" numbers)
    SUM(f.Quantity),
    SUM(f.TotalAfterTax)
FROM dbo.FactSales f
JOIN dbo.DimCustomers c    ON f.CustomerKey    = c.CustomerKey
JOIN dbo.DimLocation l     ON f.LocationKey    = l.LocationKey
JOIN dbo.DimSalesPeople sp ON f.SalespersonKey = sp.SalespersonKey
JOIN dbo.DimProducts p     ON f.ProductKey     = p.ProductKey
JOIN dbo.DimSuppliers s    ON f.SupplierKey    = s.SupplierKey
JOIN dbo.DimDate d         ON f.DateKey        = d.DateKey
GROUP BY dim1.column, dim2.column
ORDER BY ...;
```

**This is what denormalization enables** — in 3NF this would be 13+ table JOINs. In Star Schema, it's always FactSales + the Dims you need.

## Note on testing

FactSales is empty right now. The query will return 0 rows until Req 7 loads data (2013-01-01 ~ 04).
Write the query now, test it after Req 7.
