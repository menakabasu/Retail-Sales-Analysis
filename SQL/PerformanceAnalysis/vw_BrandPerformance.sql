USE Sales;
GO

DROP VIEW IF EXISTS dbo.vw_BrandPerformance;
CREATE OR ALTER VIEW dbo.vw_BrandPerformance
AS

WITH BrandYearSales AS
(
    SELECT
        d.Year AS SalesYear,
        p.Brand,

        SUM(f.SalesAmount) AS TotalSales,

        SUM(f.Quantity) AS TotalQuantity,

        COUNT(DISTINCT f.OrderID) AS TotalOrders

    FROM dbo.FactSales f

    JOIN dbo.DimProducts p
        ON f.ProductID = p.ProductID

    JOIN dbo.DimDate d
        ON f.OrderDate = d.FullDate

    GROUP BY
        d.Year,
        p.Brand
),

BrandWithPreviousYear AS
(
    SELECT
        SalesYear,
        Brand,
        TotalSales,
        TotalQuantity,
        TotalOrders,

        LAG(TotalSales) OVER
        (
            PARTITION BY Brand
            ORDER BY SalesYear
        ) AS PreviousYearSales

    FROM BrandYearSales
),
BrandAverage AS
(
    -- Step 4: Calculate average sales across Brands
    SELECT
        *,
        
        AVG(TotalSales) OVER
        (
            PARTITION BY SalesYear
        ) AS AverageBrandSales

    FROM BrandWithPreviousYear
)


SELECT
    SalesYear,
    Brand,

    TotalSales,
    TotalQuantity,
    TotalOrders,

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

    CASE
        WHEN TotalSales > AverageBrandSales
            THEN 'Above Average'

        WHEN TotalSales < AverageBrandSales
            THEN 'Below Average'

        ELSE 'Average'
    END AS SalesVsAverageStatus,

    DENSE_RANK() OVER
    (
        PARTITION BY SalesYear
        ORDER BY TotalSales DESC
    ) AS SalesRank

FROM BrandAverage;
GO


select * from dbo.vw_BrandPerformance;




CREATE OR ALTER VIEW dbo.vw_BrandPerformanceFor6months
AS
WITH BrandSales AS
(
    SELECT
        p.Brand as brand,

        -- Total sales for the available period (2023–2025)
        SUM(
            CASE
                WHEN fs.OrderDate >= '20230101'
                 AND fs.OrderDate <  '20260101'
                THEN fs.SalesAmount
                ELSE 0
            END
        ) AS TotalSales,

        -- H1 2024 sales: January to June
        SUM(
            CASE
                WHEN fs.OrderDate >= '20240101'
                 AND fs.OrderDate <  '20240701'
                THEN fs.SalesAmount
                ELSE 0
            END
        ) AS Sales_2024,

        -- H1 2025 sales: January to June
        SUM(
            CASE
                WHEN fs.OrderDate >= '20250101'
                 AND fs.OrderDate <  '20250701'
                THEN fs.SalesAmount
                ELSE 0
            END
        ) AS Sales_2025

    FROM dbo.FactSales AS fs
    INNER JOIN dbo.DimProducts AS p
        ON p.ProductID = fs.ProductID

    WHERE fs.OrderDate >= '20230101'
      AND fs.OrderDate <  '20260101'

    GROUP BY
        p.Brand
),
BrandTotals AS
(
    SELECT
        SUM(TotalSales) AS OverallSales
    FROM BrandSales
)
SELECT
    b.Brand,
    b.TotalSales,

    CAST(
        100.0 * b.TotalSales / NULLIF(t.OverallSales, 0)
        AS DECIMAL(10,4)
    ) AS SalesContributionPct,

    b.Sales_2024,
    b.Sales_2025,

    b.Sales_2025 - b.Sales_2024 AS SalesDifference,

    CAST(
        100.0 * (b.Sales_2025 - b.Sales_2024)
        / NULLIF(b.Sales_2024, 0)
        AS DECIMAL(10,2)
    ) AS YoYGrowthPct,

    CASE
         WHEN Sales_2024 = 0 AND Sales_2025 = 0
            THEN 'No Sales in Comparison Periods'
        WHEN Sales_2024 = 0
            THEN 'New Sales in 2025'
        WHEN Sales_2025 = 0
            THEN 'No Sales in 2025'
      
        WHEN 100.0 * (b.Sales_2025 - b.Sales_2024)
             / NULLIF(b.Sales_2024, 0) > 10
            THEN 'Improving'
        WHEN 100.0 * (b.Sales_2025 - b.Sales_2024)
             / NULLIF(b.Sales_2024, 0) < -10
            THEN 'Declining'
        ELSE 'No Significant Change'
    END AS PerformanceStatus

FROM BrandSales AS b
CROSS JOIN BrandTotals AS t;
GO




CREATE OR ALTER VIEW dbo.vw_QuarterlySalesComparison
AS
SELECT
    YEAR(fs.OrderDate) AS SalesYear,
    DATEPART(QUARTER, fs.OrderDate) AS QuarterNumber,
    'Q' + CAST(DATEPART(QUARTER, fs.OrderDate) AS VARCHAR(1))
        AS QuarterName,
    SUM(fs.SalesAmount) AS TotalSales
FROM dbo.FactSales AS fs
WHERE fs.OrderDate >= '20230101'
  AND fs.OrderDate <  '20260101'
GROUP BY
    YEAR(fs.OrderDate),
    DATEPART(QUARTER, fs.OrderDate);
GO


select top 10 brand,totalsales from dbo.vw_BrandPerformanceFor6months order by totalsales desc

select count(distinct brand ) from dbo.vw_BrandPerformanceFor6months

select top 10 * from dbo.vw_BrandPerformanceFor6months order by TotalSales

SELECT *
FROM dbo.vw_BrandPerformanceFor6months
ORDER BY TotalSales DESC;


SELECT
    p.Brand,
    SUM(CASE
        WHEN fs.OrderDate >= '20230101'
         AND fs.OrderDate < '20240101'
        THEN fs.SalesAmount ELSE 0
    END) AS Sales_2023,

    SUM(CASE
        WHEN fs.OrderDate >= '20240101'
         AND fs.OrderDate < '20250101'
        THEN fs.SalesAmount ELSE 0
    END) AS Sales_2024_FullYear,

    SUM(CASE
        WHEN fs.OrderDate >= '20250101'
         AND fs.OrderDate < '20250701'
        THEN fs.SalesAmount ELSE 0
    END) AS Sales_2025_H1

FROM dbo.FactSales AS fs
INNER JOIN dbo.DimProducts AS p
    ON p.ProductID = fs.ProductID
GROUP BY p.Brand
ORDER BY p.Brand;


SELECT
    p.Brand,
    p.Name AS ProductName,
    YEAR(fs.OrderDate) AS SalesYear,
    SUM(fs.SalesAmount) AS TotalSales,
    COUNT(*) AS NumberOfSales
FROM dbo.FactSales AS fs
INNER JOIN dbo.DimProducts AS p
    ON p.ProductID = fs.ProductID
WHERE p.Brand = 'Holland-Jefferson'
  AND fs.OrderDate >= '20230101'
  AND fs.OrderDate <  '20260101'
GROUP BY
    p.Brand,
    p.Name,
    YEAR(fs.OrderDate)
ORDER BY
    p.Name,
    SalesYear;

    SELECT
    p.Brand,
    p.Name AS ProductName,
    fs.OrderDate,
    fs.SalesAmount
FROM dbo.FactSales AS fs
INNER JOIN dbo.DimProducts AS p
    ON p.ProductID = fs.ProductID
WHERE p.Brand = 'Holland-Jefferson'
ORDER BY fs.OrderDate;