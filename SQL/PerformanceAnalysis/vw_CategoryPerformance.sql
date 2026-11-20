USE Sales;
GO

DROP VIEW IF EXISTS dbo.vw_CategoryPerformance;
/* ============================================================
   CATEGORY PERFORMANCE ANALYSIS
   ============================================================

   Purpose:
   Analyse the performance of each product category using:

   - Total Sales
   - Total Quantity
   - Total Orders
   - Number of Products
   - Average Order Value
   - Sales Rank

   ============================================================

   BUSINESS QUESTIONS
   ============================================================

   1. Which categories generate the highest sales?

   2. Which categories generate the lowest sales?

   3. Which categories sell the highest quantity?

   4. Which categories have the most orders?

   5. Which categories have the highest average order value?

   6. Which categories contain the most products?

   7. How do categories rank by sales?

   ============================================================ */


/* ============================================================
   1. CATEGORY PERFORMANCE VIEW
   ============================================================

   Business Questions:
   - How much sales does each category generate?
   - How much quantity does each category sell?
   - How many orders does each category receive?
   - How many products are in each category?
   - What is the average order value for each category?
   - How does each category rank by sales?

   ============================================================ */


USE Sales;
GO

CREATE OR ALTER VIEW dbo.vw_CategoryPerformance
AS

WITH CategoryYearSales AS
(
    SELECT
        d.Year AS SalesYear,
        p.Category,

        SUM(f.SalesAmount) AS TotalSales,

        SUM(f.Quantity) AS TotalQuantity,

        COUNT(DISTINCT f.OrderID) AS TotalOrders,

        COUNT(DISTINCT p.ProductID) AS NumberOfProducts

    FROM dbo.FactSales f

    JOIN dbo.DimProducts p
        ON f.ProductID = p.ProductID

    JOIN dbo.DimDate d
        ON f.OrderDate = d.FullDate

    GROUP BY
        d.Year,
        p.Category
),

CategoryWithPreviousYear AS
(
    SELECT
        SalesYear,
        Category,
        TotalSales,
        TotalQuantity,
        TotalOrders,
        NumberOfProducts,

        LAG(TotalSales) OVER
        (
            PARTITION BY Category
            ORDER BY SalesYear
        ) AS PreviousYearSales

    FROM CategoryYearSales
)

SELECT
    SalesYear,

    Category,

    TotalSales,

    TotalQuantity,

    TotalOrders,

    NumberOfProducts,

    CAST(
        TotalSales * 1.0
        / NULLIF(TotalOrders, 0)
        AS DECIMAL(10,2)
    ) AS AverageOrderValue,

    PreviousYearSales,

    TotalSales - PreviousYearSales AS SalesChange,

    CAST(
        (TotalSales - PreviousYearSales) * 100.0
        / NULLIF(PreviousYearSales, 0)
        AS DECIMAL(10,2)
    ) AS YoYGrowthPercentage,

    CASE
        WHEN PreviousYearSales IS NULL
            THEN 'No Previous Year'

        WHEN TotalSales > PreviousYearSales
            THEN 'Growth'

        WHEN TotalSales < PreviousYearSales
            THEN 'Decline'

        ELSE 'No Change'
    END AS PerformanceStatus,

    DENSE_RANK() OVER
    (
        PARTITION BY SalesYear
        ORDER BY TotalSales DESC
    ) AS SalesRank

FROM CategoryWithPreviousYear;
GO


/* ============================================================
   2. VIEW ALL CATEGORY PERFORMANCE
   ============================================================

   Business Question:
   What is the overall performance of each category?

   ============================================================ */


SELECT *
FROM dbo.vw_CategoryPerformance

ORDER BY
    SalesRank;



/* ============================================================
   3. TOP 10 CATEGORIES BY TOTAL SALES
   ============================================================

   Business Question:
   Which categories generate the highest sales?

   ============================================================ */


SELECT TOP 10
    Category,
    TotalSales

FROM dbo.vw_CategoryPerformance

ORDER BY
    TotalSales DESC;



/* ============================================================
   4. BOTTOM 10 CATEGORIES BY TOTAL SALES
   ============================================================

   Business Question:
   Which categories generate the lowest sales?

   ============================================================ */


SELECT TOP 10
    Category,
    TotalSales

FROM dbo.vw_CategoryPerformance

ORDER BY
    TotalSales ASC;



/* ============================================================
   5. TOP 10 CATEGORIES BY QUANTITY SOLD
   ============================================================

   Business Question:
   Which categories sell the highest quantity?

   ============================================================ */


SELECT TOP 10
    Category,
    TotalQuantity

FROM dbo.vw_CategoryPerformance

ORDER BY
    TotalQuantity DESC;



/* ============================================================
   6. TOP 10 CATEGORIES BY NUMBER OF ORDERS
   ============================================================

   Business Question:
   Which categories have the most orders?

   ============================================================ */


SELECT TOP 10
    Category,
    TotalOrders,
    TotalSales

FROM dbo.vw_CategoryPerformance

ORDER BY
    TotalOrders DESC;



/* ============================================================
   7. TOP 10 CATEGORIES BY AVERAGE ORDER VALUE
   ============================================================

   Business Question:
   Which categories have the highest average
   sales value per order?

   ============================================================ */


SELECT TOP 10
    Category,
    TotalOrders,
    TotalSales,
    AverageOrderValue

FROM dbo.vw_CategoryPerformance

ORDER BY
    AverageOrderValue DESC;



/* ============================================================
   8. TOP 10 CATEGORIES BY NUMBER OF PRODUCTS
   ============================================================

   Business Question:
   Which categories contain the most products?

   ============================================================ */


SELECT TOP 10
    Category,
    NumberOfProducts

FROM dbo.vw_CategoryPerformance

ORDER BY
    NumberOfProducts DESC;



/* ============================================================
   9. CATEGORY SALES RANKING
   ============================================================

   Business Question:
   How do categories rank by sales?

   ============================================================ */


SELECT
    Category,
    SalesRank,
    TotalSales

FROM dbo.vw_CategoryPerformance

ORDER BY
    SalesRank ASC;



/* ============================================================
   CATEGORY PERFORMANCE ANALYSIS SUMMARY
   ============================================================

   | # | Business Question |
   |---|-------------------|
   | 1 | Which categories generate the highest sales? |
   | 2 | Which categories generate the lowest sales? |
   | 3 | Which categories sell the highest quantity? |
   | 4 | Which categories have the most orders? |
   | 5 | Which categories have the highest average order value? |
   | 6 | Which categories contain the most products? |
   | 7 | How do categories rank by sales? |

   ============================================================ */
CREATE OR ALTER VIEW dbo.vw_CategoryTotalSales as
   select 

      p.category as Category,
        sum(fs.SalesAmount) as SalesAmount
   
     from dbo.factsales as fs
    inner join dbo.DimProducts as p
   on p.productid=fs.productid
   WHERE fs.OrderDate >= '20230101'
  AND fs.OrderDate <  '20260101'

  group by
  p.category



create or alter view dbo.vw_CategoryPerformance_6Months as 

with CategorySales as
(

select 
    
   p.category as Category,
   sum( fs.salesamount )     as TotalSales,


  

    sum(case when(fs.OrderDate >= '20240101'
             AND fs.OrderDate <  '20240701') then fs.salesamount 
       else 0 end) as Sales_2024,

 sum(case   WHEN (fs.OrderDate >= '20250101'
             AND fs.OrderDate <  '20250701') then fs.salesamount 
       else 0 end) as Sales_2025

FROM dbo.DimProducts p

    LEFT JOIN dbo.FactSales fs
        ON p.ProductID = fs.ProductID
       AND fs.OrderDate >= '20230101'
       AND fs.OrderDate <  '20260101'

    GROUP BY
        
        p.Category

    ),
TotalCategorySales as(
select sum(TotalSales) as OverAllSales
from CategorySales

)

    SELECT 
    cs.Category,
    cs.TotalSales,

    cast(100.0*TotalSales/nullif(tcs.OverAllSales,0) as decimal(10,2)) as [Sales Contribution %],

    cs.Sales_2024,
    cs.Sales_2025,

    cs.Sales_2025 - cs.Sales_2024 AS [ Sales Difference ],

    CAST(
        (cs.Sales_2025 - cs.Sales_2024) * 100.0
        / NULLIF(cs.Sales_2024, 0)
        AS DECIMAL(10,2)
    ) AS [YoY Growth %],

    CASE
          WHEN Sales_2024 = 0 AND Sales_2025 > 0
            THEN 'New Sales in 2025'
        WHEN Sales_2024 > 0 AND Sales_2025 = 0
            THEN 'No Sales in 2025'
        WHEN Sales_2024 = 0 AND Sales_2025 = 0
            THEN 'No Sales in Either Period'
        WHEN (cs.Sales_2025 - cs.Sales_2024) * 100.0
             / NULLIF(cs.Sales_2024, 0) > 10
            THEN 'Improving'
        WHEN (cs.Sales_2025 - cs.Sales_2024) * 100.0
             / NULLIF(cs.Sales_2024, 0) < -10
            THEN 'Declining'
        ELSE 'No Significant Change'
    END AS [Performance Status]

FROM CategorySales as cs
cross join TotalCategorySales as tcs


SELECT *
FROM dbo.vw_CategoryPerformance_6Months
ORDER BY TotalSales DESC;


SELECT
    Category,
    Sales_2024,
    Sales_2025
FROM dbo.vw_CategoryPerformance_6Months
ORDER BY TotalSales DESC;