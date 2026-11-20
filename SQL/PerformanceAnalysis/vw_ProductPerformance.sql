USE Sales;
GO


/* ============================================================
   PRODUCT PERFORMANCE ANALYSIS
   ============================================================

   Purpose:
   Analyse product sales performance by year using sales,
   quantity, orders, average order value, ranking,
   average comparison, and year-over-year performance.

   ============================================================

   BUSINESS QUESTIONS
   ============================================================

   1. Which products generate the highest sales?

   2. Which products generate the lowest sales?

   3. Which products have the highest quantity sold?

   4. Which products are ordered most frequently?

   5. Which products have the highest sales per order?

   6. Which products perform above or below their
      average historical sales?

   7. Which products are improving or declining compared
      with the previous year?

   8. Which products are both above average and
      increasing or decreasing year-over-year?

   ============================================================ */



/* ============================================================
   1. PRODUCT PERFORMANCE VIEW
   ============================================================

   Calculates yearly product-level performance including:

   - Total Sales
   - Total Quantity
   - Total Orders
   - Average Order Value
   - Sales Rank

   ============================================================ */


DROP VIEW IF EXISTS dbo.vw_ProductPerformance;
GO



CREATE OR ALTER VIEW dbo.vw_ProductPerformance
AS

WITH ProductYearlySales AS
(
    -- Step 1: Calculate product performance for each year
    SELECT
        YEAR(fs.OrderDate) AS Order_Year,
        p.ProductID,
        p.Name,
          p.Category,
        SUM(fs.SalesAmount) AS TotalSales,

        SUM(fs.Quantity) AS TotalQuantity,

        COUNT(DISTINCT fs.OrderID) AS TotalOrders,

        CAST(
            SUM(fs.SalesAmount) * 1.0
            / NULLIF(COUNT(DISTINCT fs.OrderID), 0)
            AS DECIMAL(18,2)
        ) AS AverageOrderValue

    FROM dbo.FactSales fs
    INNER JOIN dbo.DimProducts p
        ON fs.ProductID = p.ProductID

    GROUP BY
        YEAR(fs.OrderDate),
        p.ProductID,
        p.Name,
        p.Category
),

ProductWithPreviousYear AS
(
    -- Step 2: Get previous year's sales
    SELECT
        Order_Year,
        ProductID,
        Name,
        Category,
        TotalSales,
        TotalQuantity,
        TotalOrders,
        AverageOrderValue,

        LAG(TotalSales) OVER
        (
            PARTITION BY ProductID
            ORDER BY Order_Year
        ) AS PreviousYearSales

    FROM ProductYearlySales
),

ProductCalculations AS
(
    -- Step 3: Calculate YoY change and YoY %
    SELECT
        Order_Year,
        ProductID,
        Name,
         Category,
        TotalSales,
        PreviousYearSales,

         CASE
            WHEN TotalSales IS NULL
                THEN NULL
            WHEN PreviousYearSales IS NULL OR PreviousYearSales = 0
                THEN NULL
            ELSE TotalSales - PreviousYearSales
        END AS YoY_SalesChange,

        -- YoY Growth %
        CASE
            WHEN TotalSales IS NULL
                THEN NULL
            WHEN PreviousYearSales IS NULL OR PreviousYearSales = 0
                THEN NULL
            ELSE CAST(
                (TotalSales - PreviousYearSales) * 100.0
                / PreviousYearSales
                AS DECIMAL(10,2)
            )
        END AS YoY_GrowthPercentage,

        /*TotalSales - PreviousYearSales AS YoY_SalesChange,

        CAST(
            (TotalSales - PreviousYearSales) * 100.0
            / NULLIF(PreviousYearSales, 0)
            AS DECIMAL(10,2)
        ) AS YoY_GrowthPercentage,*/

        TotalQuantity,
        TotalOrders,
        AverageOrderValue

    FROM ProductWithPreviousYear
),

ProductAverage AS
(
    -- Step 4: Calculate average sales across products
    SELECT
        *,
        
        AVG(TotalSales) OVER
        (
            PARTITION BY Order_Year
        ) AS AverageProductSales

    FROM ProductCalculations
)

-- Step 5: Final result
SELECT

    Order_Year,

    ProductID,

    Name,
    Category,
    -- Current performance
    TotalSales,
    TotalQuantity,
    TotalOrders,
    AverageOrderValue,

    -- Previous year comparison
    PreviousYearSales,
    YoY_SalesChange,
    YoY_GrowthPercentage,

    -- Growth status
   /* CASE
        WHEN PreviousYearSales IS NULL
            THEN 'No Previous Year Data'

        WHEN YoY_SalesChange > 0
            THEN 'Improving'

        WHEN YoY_SalesChange < 0
            THEN 'Declining'

        ELSE 'No Change'
    END AS GrowthStatus,*/

    CASE

            WHEN TotalSales IS NULL
                 AND PreviousYearSales IS NULL
                THEN 'No Current/Previous Data'
            WHEN TotalSales IS NULL
                THEN 'No Current Year Data'

            WHEN PreviousYearSales IS NULL OR PreviousYearSales = 0
                THEN 'No Previous Year Data'

            WHEN (TotalSales - PreviousYearSales) * 100.0
                 / PreviousYearSales > 10
                THEN 'Improving'

            WHEN (TotalSales - PreviousYearSales) * 100.0
                 / PreviousYearSales < -10
                THEN 'Declining'

            ELSE 'No Significant Change'
        END AS PerformanceStatus,

    -- Average sales
    CAST(
        AverageProductSales
        AS DECIMAL(18,2)
    ) AS AverageProductSales,

    -- Above / Below average
    CASE
        WHEN TotalSales > AverageProductSales
            THEN 'Above Average'

        WHEN TotalSales < AverageProductSales
            THEN 'Below Average'

        ELSE 'Average'
    END AS SalesVsAverageStatus,

    -- Sales ranking
    RANK() OVER
    (
        PARTITION BY Order_Year
        ORDER BY TotalSales DESC
    ) AS SalesRank

FROM ProductAverage;
GO


SELECT 
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'FactSales'
  AND COLUMN_NAME = 'SalesAmount';
select * from dbo.vw_ProductPerformance

/* ============================================================
   2. VIEW ALL PRODUCT PERFORMANCE
   ============================================================

   Business Question:
   What is the overall yearly performance of each product?

   ============================================================ */


SELECT *
FROM dbo.vw_ProductPerformance;

SELECT name,PreviousYearSales,TotalSales,YoY_GrowthPercentage,performanceStatus
FROM dbo.vw_ProductPerformance where order_year ='2025'



/* ============================================================
   3. TOP 10 PRODUCTS BY SALES
   ============================================================

   Business Question:
   Which products generate the highest sales?

   ============================================================ */


SELECT TOP 10

    Order_year,
    Name,
    TotalSales,
    TotalQuantity,
    TotalOrders,
    SalesRank

FROM dbo.vw_ProductPerformance

ORDER BY
    TotalSales DESC;

 CREATE OR ALTER VIEW dbo.vw_ProductPerformanceTOP10PRODUCT_INEXCEL as
    
    SELECT TOP 10

    
    Name as [PRODUCT],
    TotalSales as [SALES]
    

FROM dbo.vw_ProductPerformance

ORDER BY
    TotalSales DESC;





/* ============================================================
   4. BOTTOM 10 PRODUCTS BY SALES
   ============================================================

   Business Question:
   Which products generate the lowest sales?

   ============================================================ */


SELECT TOP 10

    Order_year,
    Name,
    TotalSales,
    TotalQuantity,
    TotalOrders,
    SalesRank

FROM dbo.vw_ProductPerformance

ORDER BY
    TotalSales ASC;



/* ============================================================
   5. PRODUCTS WITH HIGHEST QUANTITY SOLD
   ============================================================

   Business Question:
   Which products have the highest quantity sold?

   ============================================================ */


SELECT TOP 10

    Order_year,
    Name,
    TotalQuantity,
    TotalSales,
    TotalOrders

FROM dbo.vw_ProductPerformance

ORDER BY
    TotalQuantity DESC;



/* ============================================================
   6. PRODUCTS WITH MOST ORDERS
   ============================================================

   Business Question:
   Which products are ordered most frequently?

   ============================================================ */


SELECT TOP 10

    Order_year,
    Name,
    TotalOrders,
    TotalSales,
    TotalQuantity

FROM dbo.vw_ProductPerformance

ORDER BY
    TotalOrders DESC;



/* ============================================================
   7. PRODUCTS WITH HIGHEST AVERAGE ORDER VALUE
   ============================================================

   Business Question:
   Which products generate the highest sales per order?

   ============================================================ */


SELECT TOP 10

    Order_year,
    Name,
    AverageOrderValue,
    TotalSales,
    TotalOrders

FROM dbo.vw_ProductPerformance

ORDER BY
    AverageOrderValue DESC;



/* ============================================================
   8. ABOVE / BELOW AVERAGE PRODUCT SALES
   ============================================================

   Business Questions:

   - Which products perform above their average historical sales?
   - Which products perform below their average historical sales?

   The average is calculated separately for each product
   across all available years.

   ============================================================ */
   SELECT
    Name,
    SalesVsAverageStatus    
FROM dbo.vw_ProductPerformance
WHERE SalesVsAverageStatus IN ('Above Average', 'Below Average')
group BY
    SalesVsAverageStatus,
    Name
ORDER BY
    SalesVsAverageStatus,
    Name;



/* ============================================================
   10. PRODUCT PERFORMANCE ANALYSIS SUMMARY
   ============================================================

   | # | Business Question |
   |---|-------------------|
   | 1 | Which products generate the highest sales? |
   | 2 | Which products generate the lowest sales? |
   | 3 | Which products have the highest quantity sold? |
   | 4 | Which products are ordered most frequently? |
   | 5 | Which products have the highest sales per order? |
   | 6 | Which products are above or below average sales? |
   | 7 | Which products are improving or declining compared with the previous year? |
   | 8 | Which products are both above average and increasing or decreasing year-over-year? |

   ============================================================ */

  
CREATE OR ALTER VIEW dbo.vw_ProductPerformanceQuarterWiseinExcel
AS 

   SELECT
    concat('Q',DATEPART(QUARTER, f.OrderDate)) as Quarter,

    sum(
    
        case when year(f.orderdate) = 2023 then salesamount else 0
        end ) as [2023 Sales],
        sum(
        case when year(f.orderdate) = 2024 then salesamount else 0
         end ) as [2024 Sales],
         sum(case when year(f.orderdate) = 2025 then salesamount else 0
        end ) as [2025 Sales]

FROM dbo.FactSales f
WHERE f.OrderDate >= '20230101'
  AND f.OrderDate <  '20260101'
GROUP BY DATEPART(QUARTER, f.OrderDate)


CREATE OR ALTER VIEW dbo.vw_ProductSales_YoY_H1 as
WITH ProductSales AS
(
    select 
         p.ProductID,
        p.Name AS ProductName,
       
       sum(case when 
        (f.OrderDate >= '20240101' AND f.OrderDate < '20240701') then f.salesamount else 0
        end )  as Sales_2024,

        sum(case when 
        (f.OrderDate >= '20250101' AND f.OrderDate < '20250701') then f.salesamount else 0
        end )  as Sales_2025



    from dbo.factsales f
    inner join dbo.dimproducts p
    on f.productid=p.productid
    WHERE
        (f.OrderDate >= '20240101' AND f.OrderDate < '20240701')
        OR
        (f.OrderDate >= '20250101' AND f.OrderDate < '20250701')

    GROUP BY
        p.ProductID,
        p.Name
)

SELECT 
    ProductID,
    ProductName,
    Sales_2024,
    Sales_2025,

    Sales_2025 - Sales_2024 AS SalesDifference,

    CAST(
        (Sales_2025 - Sales_2024) * 100.0
        / NULLIF(Sales_2024, 0)
        AS DECIMAL(10,2)
    ) AS YoYGrowthPct,

    CASE
        WHEN Sales_2024 = 0 AND Sales_2025 = 0
            THEN 'No Sales'
        WHEN Sales_2024 = 0
            THEN 'New Sales in 2025'
        WHEN Sales_2025 = 0
            THEN 'No Sales in 2025'
        WHEN (Sales_2025 - Sales_2024) * 100.0
             / NULLIF(Sales_2024, 0) > 10
            THEN 'Improving'
        WHEN (Sales_2025 - Sales_2024) * 100.0
             / NULLIF(Sales_2024, 0) < -10
            THEN 'Declining'
        ELSE 'No Significant Change'
    END AS PerformanceStatus

FROM ProductSales

create or alter view dbo.vw_ProductPerformance_6Months as 

with ProductSales as
(

select 
     p.ProductID as ProductId,
   p.name as ProductName,

   p.category,
   sum(case
    when (fs.OrderDate >= '20230101'
       AND fs.OrderDate <  '20260101') then fs.salesamount 
       else 0 end) as TotalSales,


   sum( case
    when (fs.OrderDate >= '20230101'
       AND fs.OrderDate <  '20260101') then fs.quantity 
       else 0 end) as TotalQuantity,

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
        p.ProductID,
        p.Name,
        p.Category

    )

    SELECT 
    ProductID,
    ProductName,
    TotalSales,
    TotalQuantity,
    Sales_2024,
    Sales_2025,

    Sales_2025 - Sales_2024 AS SalesDifference,

    CAST(
        (Sales_2025 - Sales_2024) * 100.0
        / NULLIF(Sales_2024, 0)
        AS DECIMAL(10,2)
    ) AS YoYGrowthPct,

    CASE
        WHEN Sales_2024 = 0 AND Sales_2025 = 0
            THEN 'No Sales'
        WHEN Sales_2024 = 0
            THEN 'New Sales in 2025'
        WHEN Sales_2025 = 0
            THEN 'No Sales in 2025'
        WHEN (Sales_2025 - Sales_2024) * 100.0
             / NULLIF(Sales_2024, 0) > 10
            THEN 'Improving'
        WHEN (Sales_2025 - Sales_2024) * 100.0
             / NULLIF(Sales_2024, 0) < -10
            THEN 'Declining'
        ELSE 'No Significant Change'
    END AS PerformanceStatus

FROM ProductSales


select * from dbo.vw_ProductPerformanceQuarterWiseinExcel order by quarter

