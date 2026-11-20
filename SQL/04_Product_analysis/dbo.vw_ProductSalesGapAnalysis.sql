
USE Sales;
GO

/*====================================================
  PRODUCT SALES GAP ANALYSIS
====================================================*/


/*====================================================
  1. CREATE MAIN VIEW
  View Name: dbo.vw_ProductSalesGapAnalysis

  Purpose:
  Identify product sales and inventory gaps.
====================================================*/

CREATE OR ALTER VIEW dbo.vw_ProductSalesGapAnalysis
AS

WITH ProductSales AS
(
    SELECT
        ProductID,
        SUM(Quantity) AS TotalQuantitySold,
        SUM(SalesAmount) AS TotalSales,

        SUM(CASE
                WHEN OrderDate >= '2024-01-01'
                 AND OrderDate < '2024-07-01'
                THEN Quantity ELSE 0
            END) AS PreviousYearQuantity,

        SUM(CASE
                WHEN OrderDate >= '2025-01-01'
                 AND OrderDate < '2025-07-01'
                THEN Quantity ELSE 0
            END) AS CurrentPeriodQuantity

    FROM dbo.FactSales
    GROUP BY ProductID
),

ProductAnalysis AS
(
    SELECT
        p.ProductID,
        p.Name,
        p.Category,
        p.Stock,
        p.Availability,

        ISNULL(ps.TotalQuantitySold, 0) AS TotalQuantitySold,
        ISNULL(ps.TotalSales, 0) AS TotalSales,
        ISNULL(ps.PreviousYearQuantity, 0) AS PreviousYearQuantity,
        ISNULL(ps.CurrentPeriodQuantity, 0) AS CurrentPeriodQuantity

    FROM dbo.DimProducts p

    LEFT JOIN ProductSales ps
        ON p.ProductID = ps.ProductID
),

GapAnalysis AS
(
    SELECT
        *,

        CASE
            WHEN PreviousYearQuantity > 0
            THEN CAST(
                (CurrentPeriodQuantity - PreviousYearQuantity)
                * 100.0 / PreviousYearQuantity
                AS DECIMAL(10,2)
            )
            ELSE NULL
        END AS SalesGrowthPercentage

    FROM ProductAnalysis
)

SELECT
    ProductID,
    Name,
    Category,
    Stock,
    Availability,
    TotalQuantitySold,
    TotalSales,
    PreviousYearQuantity,
    CurrentPeriodQuantity,
    SalesGrowthPercentage,

    CASE
        WHEN Stock IS NULL
            THEN 'Verify Stock Data'

        WHEN Availability = 'Discontinued'
             AND Stock > 0
            THEN 'Discontinued - Remaining Stock'

        WHEN Availability = 'Discontinued'
            THEN 'Discontinued Product'

        WHEN Availability IN ('Backorder', 'Pre-order')
             AND Stock > 0
            THEN 'Verify Inventory Status'

        WHEN Availability = 'Limited Stock'
             AND Stock >= 100
            THEN 'Verify Inventory Status'

        WHEN Availability = 'Out of Stock'
             AND TotalQuantitySold > 0
            THEN 'Out of Stock - Stock Record Mismatch'

        WHEN Availability = 'Out of Stock'
            THEN 'Out of Stock - No Historical Sales'

        WHEN Stock >= 100
             AND TotalQuantitySold = 0
            THEN 'High Stock - No Historical Sales'

        WHEN Stock >= 100
             AND TotalQuantitySold <= 50
            THEN 'High Stock - Low Sales'

        WHEN SalesGrowthPercentage < -10
             AND Stock > 0
            THEN 'Declining Sales - Stock Available'

        ELSE 'No Significant Gap Identified'
    END AS GapCategory,

    CASE
        WHEN Stock IS NULL
            THEN 'Verify inventory records'

        WHEN Availability = 'Discontinued'
             AND Stock > 0
            THEN 'Review remaining inventory'

        WHEN Availability = 'Discontinued'
            THEN 'Review discontinued product'

        WHEN Availability IN ('Backorder', 'Pre-order')
             AND Stock > 0
            THEN 'Verify inventory status and stock records'

        WHEN Availability = 'Limited Stock'
             AND Stock >= 100
            THEN 'Verify stock availability classification'

        WHEN Availability = 'Out of Stock'
             AND TotalQuantitySold > 0
            THEN 'Review replenishment requirements'

        WHEN Availability = 'Out of Stock'
            THEN 'Review product status'

        WHEN Stock >= 100
             AND TotalQuantitySold = 0
            THEN 'Investigate products with no sales history'

        WHEN Stock >= 100
             AND TotalQuantitySold <= 50
            THEN 'Review excess inventory'

        WHEN SalesGrowthPercentage < -10
             AND Stock > 0
            THEN 'Investigate declining demand'

        ELSE 'Continue monitoring'
    END AS RecommendedAction

FROM GapAnalysis;
GO


/*====================================================
  2. COMPLETE PRODUCT GAP ANALYSIS
  Query Name: qry_ProductSalesGapAnalysis_Complete

  Purpose:
  Display all product gap analysis results.
====================================================*/

SELECT *
FROM dbo.vw_ProductSalesGapAnalysis;
GO


/*====================================================
  3. INVENTORY ISSUES
  Query Name: qry_ProductInventoryIssues

  Purpose:
  Identify inventory-related problems.
====================================================*/

SELECT
    Name,
    Category,
    Availability,
    Stock,
    GapCategory

FROM dbo.vw_ProductSalesGapAnalysis

WHERE GapCategory IN
(
    'Verify Stock Data',
    'Discontinued - Remaining Stock',
    'Discontinued Product',
    'Verify Inventory Status',
    'Out of Stock - Stock Record Mismatch',
    'Out of Stock - No Historical Sales',
    'High Stock - No Historical Sales',
    'High Stock - Low Sales'
);
GO


/*====================================================
  4. DETAILED PRODUCT SALES PROBLEMS
  Query Name: qry_ProductSalesProblems

  Purpose:
  Identify products with no sales, low sales
  or declining sales.
====================================================*/

SELECT
    Name,
    Category,
    PreviousYearQuantity,
    CurrentPeriodQuantity,
    SalesGrowthPercentage,
    GapCategory,
    RecommendedAction

FROM dbo.vw_ProductSalesGapAnalysis

WHERE GapCategory IN
(
    'High Stock - No Historical Sales',
    'High Stock - Low Sales',
    'Declining Sales - Stock Available'
);
GO


/*====================================================
  5. INVENTORY ISSUES SUMMARY
  Query Name: qry_ProductInventoryIssuesSummary

  Purpose:
  Calculate total inventory issues,
  high-stock issues and stock mismatches.
====================================================*/

SELECT
    COUNT(*) AS InventoryIssues,

    SUM(CASE
        WHEN GapCategory IN
        (
            'High Stock - No Historical Sales',
            'High Stock - Low Sales'
        )
        THEN 1 ELSE 0
    END) AS HighStockIssues,

    SUM(CASE
        WHEN GapCategory IN
        (
            'Out of Stock - Stock Record Mismatch',
            'Verify Inventory Status'
        )
        THEN 1 ELSE 0
    END) AS StockMismatches

FROM dbo.vw_ProductSalesGapAnalysis;
GO


/*====================================================
  6. PRODUCT SALES PROBLEMS SUMMARY
  Query Name: qry_ProductSalesProblemsSummary

  Purpose:
  Count products with no sales, low sales
  and declining sales.
====================================================*/

SELECT
    SUM(CASE
        WHEN GapCategory = 'High Stock - No Historical Sales'
        THEN 1 ELSE 0
    END) AS NoSales,

    SUM(CASE
        WHEN GapCategory = 'High Stock - Low Sales'
        THEN 1 ELSE 0
    END) AS LowSales,

    SUM(CASE
        WHEN GapCategory = 'Declining Sales - Stock Available'
        THEN 1 ELSE 0
    END) AS DecliningSales

FROM dbo.vw_ProductSalesGapAnalysis;
GO
