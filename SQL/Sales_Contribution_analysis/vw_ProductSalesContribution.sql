USE Sales;
GO


/* =========================================================
   1. PRODUCT SALES CONTRIBUTION VIEW
   Purpose:
   Calculate each product's sales, total sales,
   and percentage contribution to total sales.
   ========================================================= */

DROP VIEW IF EXISTS dbo.vw_Product_Sales_contribution;
GO

CREATE OR ALTER VIEW dbo.vw_Product_Sales_contribution
AS
SELECT
    p.ProductID AS ProductID,
    p.Name AS Name,

    -- Total sales for each product
    SUM(f.SalesAmount) AS Product_Sales,

    -- Total sales across all products
    SUM(SUM(f.SalesAmount)) OVER () AS TotalSales,

    -- Product contribution to total sales
    CAST(
        SUM(f.SalesAmount) * 100.0
        / SUM(SUM(f.SalesAmount)) OVER ()
        AS DECIMAL(10, 2)
    ) AS SalesContributionPercentage

FROM FactSales f

INNER JOIN DimProducts p
    ON f.ProductID = p.ProductID

GROUP BY
    p.ProductID,
    p.Name;
GO


/* =========================================================
   2. VIEW ALL PRODUCTS BY SALES CONTRIBUTION
   Purpose:
   See every product ranked from highest to lowest
   sales contribution.
   ========================================================= */

SELECT *
FROM dbo.vw_Product_Sales_contribution
ORDER BY SalesContributionPercentage DESC;


/* =========================================================
   3. TOP 10 PRODUCTS BY SALES CONTRIBUTION
   Purpose:
   Identify the 10 products contributing the most
   to total sales.
   ========================================================= */

SELECT TOP 10
    Name,
    Product_Sales,
    SalesContributionPercentage
FROM dbo.vw_Product_Sales_contribution
ORDER BY SalesContributionPercentage DESC;


/* =========================================================
   4. CUMULATIVE PRODUCT SALES CONTRIBUTION
   Purpose:
   Calculate the cumulative percentage of sales
   contributed by products.
   
   This is used for Pareto / 80-20 analysis.
   ========================================================= */

SELECT
    Name,
    Product_Sales,
    SalesContributionPercentage,

    SUM(SalesContributionPercentage) OVER (
        ORDER BY Product_Sales DESC
    ) AS CumulativeContributionPercentage

FROM dbo.vw_Product_Sales_contribution
ORDER BY Product_Sales DESC;