
USE Sales;
GO


-- =========================================================
-- SALES ANALYSIS
-- MONTHLY MoM GROWTH & ADVANCED ANALYSIS
-- =========================================================


-- =========================================================
-- 0. CREATE MONTHLY SALES GROWTH VIEW
-- =========================================================

CREATE OR ALTER VIEW dbo.vw_MonthlySalesGrowth
AS

WITH MonthlySales AS
(
    SELECT
        d.Year AS SalesYear,
        d.Month AS MonthNumber,
        d.MonthName,

        SUM(f.SalesAmount) AS TotalSales,
        COUNT(DISTINCT f.CustomerID) AS TotalCustomers,
        SUM(f.Quantity) AS TotalQuantity

    FROM dbo.FactSales AS f

    INNER JOIN dbo.DimDate AS d
        ON f.OrderDate = d.FullDate

    GROUP BY
        d.Year,
        d.Month,
        d.MonthName
),

PreviousMonth AS
(
    SELECT
        SalesYear,
        MonthNumber,
        MonthName,
        TotalSales,
        TotalCustomers,
        TotalQuantity,

        LAG(TotalSales) OVER
        (
            ORDER BY
                SalesYear,
                MonthNumber
        ) AS PreviousMonthSales

    FROM MonthlySales
)

SELECT
    SalesYear,
    MonthNumber,
    MonthName,
    TotalSales,
    TotalCustomers,
    TotalQuantity,
    PreviousMonthSales,

    TotalSales - PreviousMonthSales AS SalesChange,

    ROUND(
        (TotalSales - PreviousMonthSales) * 100.0
        / NULLIF(PreviousMonthSales, 0),
        2
    ) AS MoMGrowthPercentage

FROM PreviousMonth;
GO


-- =========================================================
-- CHECK THE VIEW
-- =========================================================

SELECT *
FROM dbo.vw_MonthlySalesGrowth
ORDER BY
    SalesYear,
    MonthNumber;


-- =========================================================
-- 1. MONTHLY MoM GROWTH TREND
-- Business Question:
-- How did monthly sales change compared with the previous month?
-- =========================================================

SELECT
    SalesYear,
    MonthNumber,
    MonthName,
    TotalSales,
    PreviousMonthSales,
    SalesChange,
    MoMGrowthPercentage

FROM dbo.vw_MonthlySalesGrowth

WHERE PreviousMonthSales IS NOT NULL

ORDER BY
    SalesYear,
    MonthNumber;


-- =========================================================
-- 2. HIGHEST MoM GROWTH
-- Business Question:
-- Which month experienced the highest percentage increase?
-- =========================================================

SELECT TOP 1
    SalesYear,
    MonthNumber,
    MonthName,
    TotalSales,
    PreviousMonthSales,
    SalesChange,
    MoMGrowthPercentage

FROM dbo.vw_MonthlySalesGrowth

WHERE PreviousMonthSales IS NOT NULL

ORDER BY
    MoMGrowthPercentage DESC;


-- =========================================================
-- 3. LARGEST MoM DECLINE
-- Business Question:
-- Which month experienced the largest percentage decline?
-- =========================================================

SELECT TOP 1
    SalesYear,
    MonthNumber,
    MonthName,
    TotalSales,
    PreviousMonthSales,
    SalesChange,
    MoMGrowthPercentage

FROM dbo.vw_MonthlySalesGrowth

WHERE PreviousMonthSales IS NOT NULL

ORDER BY
    MoMGrowthPercentage ASC;


-- =========================================================
-- 4. GROWTH VS DECLINE COUNT
-- Business Question:
-- How many months experienced growth, decline or no change?
-- =========================================================

SELECT
    SUM(
        CASE
            WHEN MoMGrowthPercentage > 0 THEN 1
            ELSE 0
        END
    ) AS GrowthMonths,

    SUM(
        CASE
            WHEN MoMGrowthPercentage < 0 THEN 1
            ELSE 0
        END
    ) AS DeclineMonths,

    SUM(
        CASE
            WHEN MoMGrowthPercentage = 0 THEN 1
            ELSE 0
        END
    ) AS NoChangeMonths

FROM dbo.vw_MonthlySalesGrowth

WHERE PreviousMonthSales IS NOT NULL;


-- =========================================================
-- 5. AVERAGE MoM GROWTH
-- Business Question:
-- What was the average monthly sales growth rate?
-- =========================================================

SELECT
    ROUND(
        AVG(MoMGrowthPercentage),
        2
    ) AS AverageMoMGrowthPercentage

FROM dbo.vw_MonthlySalesGrowth

WHERE PreviousMonthSales IS NOT NULL;


-- =========================================================
-- 6. UNUSUALLY LARGE SALES MOVEMENTS
-- Business Question:
-- Which months experienced unusually large increases
-- or decreases?
-- Threshold: +20% / -20%
-- =========================================================

SELECT
    SalesYear,
    MonthNumber,
    MonthName,
    TotalSales,
    PreviousMonthSales,
    SalesChange,
    MoMGrowthPercentage,

    CASE
        WHEN MoMGrowthPercentage >= 20
            THEN 'Unusually High Growth'

        WHEN MoMGrowthPercentage <= -20
            THEN 'Unusually Large Decline'

        ELSE 'Normal'
    END AS MovementType

FROM dbo.vw_MonthlySalesGrowth

WHERE
    MoMGrowthPercentage >= 20
    OR MoMGrowthPercentage <= -20

ORDER BY
    SalesYear,
    MonthNumber;


-- =========================================================
-- 7. SALES RECOVERY ANALYSIS
-- Business Question:
-- Which months showed recovery after a previous decline?
-- =========================================================

WITH SalesMovement AS
(
    SELECT
        SalesYear,
        MonthNumber,
        MonthName,
        TotalSales,
        MoMGrowthPercentage,

        LAG(MoMGrowthPercentage) OVER
        (
            ORDER BY
                SalesYear,
                MonthNumber
        ) AS PreviousMonthGrowth

    FROM dbo.vw_MonthlySalesGrowth
)

SELECT
    SalesYear,
    MonthNumber,
    MonthName,
    TotalSales,
    PreviousMonthGrowth,
    MoMGrowthPercentage AS CurrentMonthGrowth,

    CASE
        WHEN PreviousMonthGrowth < 0
             AND MoMGrowthPercentage > 0
            THEN 'Recovered After Decline'

        ELSE 'No Recovery'
    END AS RecoveryStatus

FROM SalesMovement

WHERE
    PreviousMonthGrowth < 0
    AND MoMGrowthPercentage > 0

ORDER BY
    SalesYear,
    MonthNumber;


-- =========================================================
-- 8. MoM GROWTH VOLATILITY
-- Business Question:
-- How much does monthly sales growth fluctuate?
-- =========================================================

SELECT
    ROUND(
        STDEV(MoMGrowthPercentage),
        2
    ) AS MoMGrowthVolatility

FROM dbo.vw_MonthlySalesGrowth

WHERE PreviousMonthSales IS NOT NULL;


-- =========================================================
-- 9. CUMULATIVE SALES ACROSS ALL YEARS
-- Business Question:
-- How do sales accumulate continuously across the
-- entire sales period?
-- =========================================================

WITH SalesYearPlusMonthCumulative AS
(
    SELECT
        SalesYear,
        MonthNumber,
        MonthName,
        TotalSales,
        TotalCustomers,
        TotalQuantity,

        SUM(TotalSales) OVER
        (
            ORDER BY
                SalesYear,
                MonthNumber
        ) AS CumulativeSales

    FROM dbo.vw_MonthlySalesGrowth
)

SELECT
    SalesYear,
    MonthNumber,
    MonthName,
    TotalSales,
    TotalCustomers,
    TotalQuantity,
    CumulativeSales

FROM SalesYearPlusMonthCumulative

ORDER BY
    SalesYear,
    MonthNumber;


-- =========================================================
-- 10. YEAR-WISE CUMULATIVE SALES
-- Business Question:
-- How do sales accumulate month by month within
-- each individual year?
-- =========================================================

WITH SalesYearWiseCumulative AS
(
    SELECT
        SalesYear,
        MonthNumber,
        MonthName,
        TotalSales,
        TotalCustomers,
        TotalQuantity,

        SUM(TotalSales) OVER
        (
            PARTITION BY SalesYear
            ORDER BY MonthNumber
        ) AS CumulativeSales

    FROM dbo.vw_MonthlySalesGrowth
)

SELECT
    SalesYear,
    MonthNumber,
    MonthName,
    TotalSales,
    TotalCustomers,
    TotalQuantity,
    CumulativeSales

FROM SalesYearWiseCumulative

ORDER BY
    SalesYear,
    MonthNumber;


CREATE OR ALTER VIEW dbo.vw_MonthlySalesFormatted
AS

SELECT
    SalesYear AS [Year],
    MonthName AS [Month],
    TotalSales AS [Sale],

    CASE
        WHEN PreviousMonthSales IS NULL
             OR PreviousMonthSales = 0
            THEN '-'

        ELSE CONCAT(MoMGrowthPercentage, '%')
    END AS [YoY Growth]

FROM dbo.vw_MonthlySalesGrowth;


CREATE OR ALTER VIEW dbo.vw_MonthlySales_2024_2025
AS

SELECT
    MonthName AS [Month],

    SUM(
        CASE
            WHEN SalesYear = 2024 THEN TotalSales
        END
    ) AS [2024 Sales],

    SUM(
        CASE
            WHEN SalesYear = 2025 THEN TotalSales
        END
    ) AS [2025 Sales]

FROM dbo.vw_MonthlySalesGrowth

WHERE SalesYear IN (2024, 2025)

GROUP BY
    MonthName,
    MonthNumber;


SELECT *
FROM dbo.vw_MonthlySales_2024_2025;


SELECT
    SalesAmount AS TotalSales

FROM dbo.FactSales

WHERE OrderDate >= '2024-01-01'
  AND OrderDate < '2024-02-01';


SELECT
    SalesYear,
    MonthNumber,
    MonthName,
    TotalSales

FROM dbo.vw_MonthlySalesGrowth

WHERE SalesYear = 2025

ORDER BY MonthNumber;


SELECT
    MIN(OrderDate) AS FirstOrderDate,
    MAX(OrderDate) AS LastOrderDate,
    COUNT(*) AS TotalSalesRows

FROM dbo.FactSales;


SELECT
    (
        SELECT SUM(TotalSales)
        FROM dbo.vw_MonthlySalesGrowth
    ) AS TotalSales,

    (
        SELECT COUNT(*)
        FROM dbo.vw_MonthlySalesGrowth
    ) AS MonthsAnalysed,

    (
        SELECT TOP 1 SalesYear
        FROM dbo.vw_MonthlySalesGrowth
        GROUP BY SalesYear
        ORDER BY SUM(TotalSales) DESC
    ) AS BestSalesYear,

    (
        SELECT TOP 1
            CONCAT(MonthName, ' ', SalesYear)
        FROM dbo.vw_MonthlySalesGrowth
        ORDER BY TotalSales ASC
    ) AS LowestSalesMonth;
