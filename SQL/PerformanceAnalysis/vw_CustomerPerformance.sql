USE Sales;
GO


/* ============================================================
   CUSTOMER PERFORMANCE ANALYSIS
   ============================================================

   Purpose:
   Analyse customer sales performance using:

   - Total Sales
   - Total Quantity
   - Total Orders
   - Average Order Value
   - Sales Rank

   ============================================================

   BUSINESS QUESTIONS
   ============================================================

   1. Which customers generate the highest sales?

   2. Which customers generate the lowest sales?

   3. Which customers place the most orders?

   4. Which customers purchase the highest quantity?

   5. Which customers have the highest sales rank?

   6. Which customers generate the highest average
      sales per order?

   ============================================================ */


/* ============================================================
   1. CUSTOMER PERFORMANCE VIEW
   ============================================================

   Business Questions:
   - How much does each customer spend?
   - How many orders does each customer place?
   - How much quantity does each customer purchase?
   - What is the customer's average order value?
   - What is the customer's sales rank?

   ============================================================ */
drop view if exists dbo.vw_CustomerPerformance

CREATE OR ALTER VIEW dbo.vw_CustomerPerformance

AS

WITH CustomerYearlySales AS
(
    SELECT
        YEAR(fs.OrderDate) AS OrderYear,
        c.CustomerID,
        CONCAT(c.FirstName, ' ', c.LastName) AS CustomerName,
        c.Country,
        c.City,

        SUM(fs.SalesAmount) AS TotalSales,
        SUM(fs.Quantity) AS TotalQuantity,
        COUNT(DISTINCT fs.OrderID) AS TotalOrders

    FROM dbo.FactSales fs

    INNER JOIN dbo.DimCustomers c
        ON fs.CustomerID = c.CustomerID

    GROUP BY
        YEAR(fs.OrderDate),
        c.CustomerID,
        c.FirstName,
        c.LastName,
        c.Country,
        c.City
),

CustomerYearlyPerformance AS
(
    SELECT
        OrderYear,
        CustomerID,
        CustomerName,
        Country,
        City,
        TotalSales,
        TotalQuantity,
        TotalOrders,

        -- Average Order Value
        CAST(
            TotalSales / NULLIF(TotalOrders, 0)
            AS DECIMAL(18,2)
        ) AS AOV,

        -- Sales Rank within each year
        RANK() OVER
        (
            PARTITION BY OrderYear
            ORDER BY TotalSales DESC
        ) AS SalesRank,

        -- Previous year's sales
        LAG(TotalSales) OVER
        (
            PARTITION BY CustomerID
            ORDER BY OrderYear
        ) AS PreviousYearSales

    FROM CustomerYearlySales
),

CustomerPerformance AS
(
    SELECT
        *,

        -- YoY Sales Change
        TotalSales - PreviousYearSales AS SalesChange,

        -- YoY Growth %
        CAST(
            (TotalSales - PreviousYearSales) * 100.0
            / NULLIF(PreviousYearSales, 0)
            AS DECIMAL(10,2)
        ) AS YoYGrowthPct

    FROM CustomerYearlyPerformance
),

CustomerContribution AS
(
    SELECT
        *,

        -- Customer contribution to total sales for that year
        CAST(
            TotalSales * 100.0
            / NULLIF(
                SUM(TotalSales) OVER
                (
                    PARTITION BY OrderYear
                ), 0
            )
            AS DECIMAL(10,2)
        ) AS SalesContributionPct,

        -- Cumulative sales %
        CAST(
            SUM(TotalSales) OVER
            (
                PARTITION BY OrderYear
                ORDER BY TotalSales DESC, CustomerID
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) * 100.0
            / NULLIF(
                SUM(TotalSales) OVER
                (
                    PARTITION BY OrderYear
                ), 0
            )
            AS DECIMAL(10,2)
        ) AS CumulativeSalesPct

    FROM CustomerPerformance
),

CustomerPareto AS
(
    SELECT
        *,

        -- Number of customers in that year
        COUNT(*) OVER
        (
            PARTITION BY OrderYear
        ) AS TotalCustomers,

        -- Customer percentage of total customer base
        CAST(
            100.0 / NULLIF(
                COUNT(*) OVER
                (
                    PARTITION BY OrderYear
                ), 0
            )
            AS DECIMAL(10,2)
        ) AS CustomerBasePct

    FROM CustomerContribution
)

SELECT

    --------------------------------------------------
    -- CUSTOMER INFORMATION
    --------------------------------------------------

    OrderYear,
    CustomerID,
    CustomerName,
    Country,
    City,

    --------------------------------------------------
    -- SALES PERFORMANCE
    --------------------------------------------------

    TotalSales,
    TotalQuantity,
    TotalOrders,
    AOV,

    --------------------------------------------------
    -- RANKING
    --------------------------------------------------

    SalesRank,

    --------------------------------------------------
    -- CONTRIBUTION
    --------------------------------------------------

    SalesContributionPct,

    --------------------------------------------------
    -- PARETO
    --------------------------------------------------

    CumulativeSalesPct,

    CASE
        WHEN CumulativeSalesPct <= 80
            THEN 'Top 80% Sales Customers'
        ELSE 'Remaining Customers'
    END AS ParetoSegment,

    TotalCustomers,

    CustomerBasePct,

    --------------------------------------------------
    -- YEAR-OVER-YEAR PERFORMANCE
    --------------------------------------------------

    PreviousYearSales,
    SalesChange,
    YoYGrowthPct,

    --------------------------------------------------
    -- PERFORMANCE STATUS
    --------------------------------------------------

    CASE

        -- No previous year
        WHEN PreviousYearSales IS NULL
             OR PreviousYearSales = 0
        THEN 'No Previous Year Data'

        -- Current sales missing/zero
        WHEN TotalSales IS NULL
             OR TotalSales = 0
        THEN 'No Current Year Data'

        -- Both current and previous are zero
        WHEN TotalSales = 0
             AND PreviousYearSales = 0
        THEN 'No Sales'

        -- Growth
        WHEN YoYGrowthPct > 10
        THEN 'Improving'

        -- Decline
        WHEN YoYGrowthPct < -10
        THEN 'Declining'

        -- Between -10% and +10%
        ELSE 'No Significant Change'

    END AS PerformanceStatus

FROM CustomerPareto;

/* ============================================================
   2. TOP 10 CUSTOMERS BY TOTAL SALES
   ============================================================

   Business Question:
   Which customers generate the highest total sales?

   ============================================================ */


SELECT TOP 200
    *
FROM dbo.vw_CustomerPerformance

ORDER BY
    TotalSales DESC;



/* ============================================================
   3. BOTTOM 10 CUSTOMERS BY TOTAL SALES
   ============================================================

   Business Question:
   Which customers generate the lowest total sales?

   ============================================================ */


SELECT TOP 10 country, sum(TotalSales) as total
    
FROM dbo.vw_CustomerPerformance
WHERE OrderYear =2025

group by Country

ORDER BY
    total desc;


SELECT *
    
FROM dbo.vw_CustomerPerformance
WHERE OrderYear =2025

select customerid,sum(totalsales) from dbo.vw_CustomerPerformance group by  customerid having count(customerid)>=2

ORDER BY
    TotalSales desc;




/* ============================================================
   4. TOP 10 CUSTOMERS BY TOTAL ORDERS
   ============================================================

   Business Question:
   Which customers place the most orders?

   ============================================================ */


SELECT TOP 10
    *
FROM dbo.vw_CustomerPerformance

ORDER BY
    TotalOrders DESC;



/* ============================================================
   5. TOP 10 CUSTOMERS BY TOTAL QUANTITY
   ============================================================

   Business Question:
   Which customers purchase the highest quantity?

   ============================================================ */


SELECT TOP 10
    *
FROM dbo.vw_CustomerPerformance

ORDER BY
    TotalQuantity DESC;



/* ============================================================
   6. TOP 10 CUSTOMERS BY SALES RANK
   ============================================================

   Business Question:
   Which customers have the highest sales ranking?

   ============================================================ */


SELECT TOP 10
    *
FROM dbo.vw_CustomerPerformance

ORDER BY
    SalesRank ASC;



/* ============================================================
   7. TOP 10 CUSTOMERS BY AVERAGE ORDER VALUE
   ============================================================

   Business Question:
   Which customers generate the highest average
   sales value per order?

   ============================================================ */


SELECT TOP 10
    CustomerID,
    CustomerName,
    TotalSales,
    TotalOrders,
    AverageOrderValue,
    SalesRank

FROM dbo.vw_CustomerPerformance

ORDER BY
    AverageOrderValue DESC;



/* ============================================================
   CUSTOMER PERFORMANCE ANALYSIS SUMMARY
   ============================================================

   | # | Business Question |
   |---|-------------------|
   | 1 | Which customers generate the highest sales? |
   | 2 | Which customers generate the lowest sales? |
   | 3 | Which customers place the most orders? |
   | 4 | Which customers purchase the highest quantity? |
   | 5 | Which customers have the highest sales ranking? |
   | 6 | Which customers generate the highest average sales per order? |

   ============================================================ */

   SELECT TOP 10
    country,sum(totalsales) as sales
    

FROM dbo.vw_CustomerPerformance
group by country
order by sales desc


   SELECT TOP 10
    City,sum(totalsales) as sales
    

FROM dbo.vw_CustomerPerformance
group by City
order by sales desc



CREATE OR ALTER VIEW dbo.vw_CustomerAnalysis
AS
WITH CustomerBase AS
(
    SELECT
        cp.CustomerID,
        dc.Country,
        dc.City,
        cp.CustomerName,
        cp.TotalSales,
        cp.TotalQuantity,
        cp.TotalOrders,
        cp. AOV
    FROM dbo.vw_CustomerPerformance AS cp
    LEFT JOIN dbo.DimCustomers AS dc
        ON cp.CustomerID = dc.CustomerID
),
CustomerRanks AS
(
    SELECT
        *,
        NTILE(4) OVER (
            ORDER BY TotalSales DESC
        ) AS SalesQuartile,
        RANK() OVER (
            ORDER BY TotalSales DESC
        ) AS SalesRank,
        SUM(TotalSales) OVER () AS OverallSales,
        COUNT(*) OVER () AS TotalCustomers
    FROM CustomerBase
)

SELECT
    CustomerID,
    CustomerName,
    Country,
    City,
    TotalSales,
    TotalQuantity,
    TotalOrders,
     AOV,
    SalesRank,
    SalesQuartile,

    CAST(
        100.0 * TotalSales /
        NULLIF(OverallSales, 0)
        AS DECIMAL(10,2)
    ) AS SalesContributionPct,

    CASE
        WHEN SalesQuartile = 1 THEN 'High Value'
        WHEN SalesQuartile IN (2,3) THEN 'Medium Value'
        ELSE 'Low Value'
    END AS CustomerSegment

FROM CustomerRanks;
GO

select * from dbo.vw_CustomerAnalysis

SELECT
    CustomerSegment,
    COUNT(DISTINCT CustomerID) AS NumberOfCustomers
FROM dbo.vw_CustomerAnalysis
GROUP BY CustomerSegment
ORDER BY
    CASE CustomerSegment
        WHEN 'High Value' THEN 1
        WHEN 'Medium Value' THEN 2
        WHEN 'Low Value' THEN 3
        ELSE 4
    END;


select 
    CustomerID,
    CustomerName,
    Country,
    City,
    TotalSales,
    SalesContributionPct,
    CustomerSegment
    from dbo.vw_CustomerAnalysis order by TotalSales desc

select top 10 country,sum(TotalSales)  from dbo.vw_CustomerAnalysis group by country order by sum(TotalSales) desc

SELECT
    ca.CustomerID,
    cp.OrderYear,
    cp.TotalSales,
    cp.PreviousYearSales,
    cp.SalesChange,
    cp.YoYGrowthPct,
    cp.PerformanceStatus
   
FROM dbo.vw_CustomerAnalysis AS ca
INNER JOIN dbo.vw_CustomerPerformance AS cp
    ON ca.CustomerID = cp.CustomerID
WHERE ca.CustomerSegment = 'High Value'
  AND cp.OrderYear = 2025
ORDER BY cp.SalesChange ASC;


SELECT TOP 10
    CustomerID,
    CustomerName,
    TotalSales,
    CustomerSegment
FROM dbo.vw_CustomerAnalysis
WHERE CustomerSegment = 'High Value'
ORDER BY TotalSales DESC;




CREATE VIEW dbo.vw_HighValueCustomerYoY
AS
WITH CustomerYearlySales AS
(
    SELECT
        fs.CustomerID,
        YEAR(fs.OrderDate) AS OrderYear,
        SUM(fs.SalesAmount) AS TotalSales
    FROM dbo.FactSales AS fs
    GROUP BY
        fs.CustomerID,
        YEAR(fs.OrderDate)
),
CustomerYoY AS
(
    SELECT
        CustomerID,
        OrderYear,
        TotalSales,
        LAG(TotalSales) OVER (
            PARTITION BY CustomerID
            ORDER BY OrderYear
        ) AS PreviousYearSales
    FROM CustomerYearlySales
)
SELECT
    cy.CustomerID,
    cy.OrderYear,
    cy.TotalSales,
    cy.PreviousYearSales,
    cy.TotalSales - cy.PreviousYearSales AS SalesChange,
    CAST(
        100.0 * (cy.TotalSales - cy.PreviousYearSales)
        / NULLIF(cy.PreviousYearSales, 0)
        AS DECIMAL(10,2)
    ) AS YoYGrowthPct,
    CASE
        WHEN cy.PreviousYearSales IS NULL
            THEN 'No Previous Year Data'
        WHEN cy.PreviousYearSales = 0
            THEN 'No Previous Year Data'
        WHEN 100.0 * (cy.TotalSales - cy.PreviousYearSales)
             / NULLIF(cy.PreviousYearSales, 0) > 10
            THEN 'Improving'
        WHEN 100.0 * (cy.TotalSales - cy.PreviousYearSales)
             / NULLIF(cy.PreviousYearSales, 0) < -10
            THEN 'Declining'
        ELSE 'No Significant Change'
    END AS PerformanceStatus
FROM CustomerYoY AS cy
WHERE EXISTS
(
    SELECT 1
    FROM dbo.vw_CustomerAnalysis AS ca
    WHERE ca.CustomerID = cy.CustomerID
      AND ca.CustomerSegment = 'High Value'
);


SELECT
    CustomerID,
    COUNT(*) AS Row_Count
FROM dbo.vw_CustomerAnalysis
WHERE CustomerSegment = 'High Value'
GROUP BY CustomerID
HAVING COUNT(*) > 1
ORDER BY Row_Count DESC;


SELECT *
FROM dbo.vw_CustomerAnalysis
WHERE CustomerSegment = 'High Value'
  AND CustomerID IN
      (44, 117, 159, 598, 614, 697, 773, 781, 803, 846, 933)
ORDER BY CustomerID;

CREATE or Alter VIEW dbo.vw_HighValueCustomerH1H2 as

with LifetimeSales as (
    select customerid ,
    sum(salesamount) as LifeTimeSales
    from dbo.factsales
    group by customerid


),


CustomerSegments as(

    select customerid,
NTILE(4) over(
    order by LifeTimeSales desc
) as SalesQuartile
from LifetimeSales
),


CustomerH1Sales as(

select customerid,

sum(case  WHEN OrderDate >= '20240101'
             AND OrderDate <  '20240701' then salesamount 
    else 0 end)  AS H1_2024_Sales,

    sum(case  WHEN OrderDate >= '20250101'
             AND OrderDate <  '20250701' then salesamount 
    else 0 end)  AS H1_2025_Sales


from dbo.factsales 
group by CustomerID
)
select 
cs.customerid,
ls.LifeTimeSales,
chs.H1_2024_Sales,
chs.H1_2025_Sales,
chs.H1_2025_Sales - chs.H1_2024_Sales
        AS SalesChange,


        CASE
    WHEN H1_2024_Sales > 0
     AND H1_2025_Sales = 0
        THEN 'Lost Sales'

    WHEN H1_2024_Sales = 0
     AND H1_2025_Sales > 0
        THEN 'New or Reactivated'

    WHEN H1_2024_Sales = 0
     AND H1_2025_Sales = 0
        THEN 'No Sales Both Periods'

    WHEN H1_2025_Sales < H1_2024_Sales
        THEN 'Decreased'

    WHEN H1_2025_Sales > H1_2024_Sales
        THEN 'Increased'

    ELSE 'Stable'
END AS SalesTrend
from CustomerSegments cs
inner join CustomerH1Sales chs
 on cs.customerid = chs.customerid
 INNER JOIN LifetimeSales AS ls
    ON cs.CustomerID = ls.CustomerID
 where cs.SalesQuartile =1 





select top 10 customerid,
H1_2024_Sales,
H1_2025_Sales,SalesChange,SalesTrend from dbo.vw_HighValueCustomerH1H2 ORDER BY LifeTimeSales DESC, CustomerID;
  select  * from dbo.vw_HighValueCustomerH1H2  ORDER BY LifeTimeSales DESC, CustomerID;

  select salestrend,count(*) as ActualCount from dbo.vw_HighValueCustomerH1H2 group by salestrend

  select customerid,p.ProductID,p.category,p.stock,p.Availability from dbo.FactSales fs inner join dbo.dimproducts p on fs.ProductID = p.ProductID where fs.CustomerID =798