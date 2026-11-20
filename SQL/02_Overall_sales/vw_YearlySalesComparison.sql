use Sales
--create or alter view dbo.Overall_Comparable_YoY_Sales as--
Create or alter view vw_YearlySalesComparison as 
WITH ComparableSales AS
(
    SELECT
        YEAR(OrderDate) AS SalesYear,
        SUM(SalesAmount) AS TotalSales
    FROM dbo.FactSales
    WHERE
       
    OrderDate >= '2024-01-01'
    AND OrderDate < '2026-01-01'
    GROUP BY YEAR(OrderDate)
),
ComparableSalesOutput as (
SELECT
    SalesYear,
    TotalSales,
    CASE
        WHEN SalesYear = 2024 THEN TotalSales
        else 0
    END AS Sales_2024,
    CASE
        WHEN SalesYear = 2025 THEN TotalSales
        else 0
    END AS Sales_2025
FROM ComparableSales

),


ComparableSalesDifference AS
(
    SELECT
    
        SUM(Sales_2024) AS Sales_2024,
        SUM(Sales_2025) AS Sales_2025,
        SUM(Sales_2025) - SUM(Sales_2024)
            AS Sales_Difference
    FROM ComparableSalesOutput


),
ComparableSalesGrowth AS
(
    SELECT
        Sales_2024,
        Sales_2025,
        Sales_Difference,
        CAST(
            100.0 * Sales_Difference
            / NULLIF(Sales_2024, 0)
            AS DECIMAL(10,2)
        ) AS YoYGrowthPct
    FROM ComparableSalesDifference
)


SELECT Sales_2024, Sales_2025,Sales_Difference,YoYGrowthPct
FROM ComparableSalesGrowth

select * from vw_YearlySalesComparison





CREATE OR ALTER VIEW dbo.vw_ComparableSalesYoY
AS

WITH ComparableSales AS
(
    SELECT
        YEAR(OrderDate) AS SalesYear,
        SUM(SalesAmount) AS TotalSales
    FROM dbo.FactSales
    WHERE
        (
            OrderDate >= '2024-01-01'
            AND OrderDate < '2024-07-01'
        )
        OR
        (
            OrderDate >= '2025-01-01'
            AND OrderDate < '2025-07-01'
        )
    GROUP BY YEAR(OrderDate)
),


ComparableSalesOutput AS
(
    SELECT
        SalesYear,
        TotalSales,

        CASE
            WHEN SalesYear = 2024 THEN TotalSales
            ELSE 0
        END AS Sales_2024,

        CASE
            WHEN SalesYear = 2025 THEN TotalSales
            ELSE 0
        END AS Sales_2025

    FROM ComparableSales
),




ComparableSalesDifference AS
(
    SELECT
        SUM(Sales_2024) AS Sales_2024,
        SUM(Sales_2025) AS Sales_2025,

        SUM(Sales_2025) - SUM(Sales_2024)
            AS Sales_Difference

    FROM ComparableSalesOutput
),

ComparableSalesGrowth AS
(
    SELECT
        Sales_2024,
        Sales_2025,
        Sales_Difference,

        CAST(
            100.0 * Sales_Difference
            / NULLIF(Sales_2024, 0)
            AS DECIMAL(10,2)
        ) AS YoYGrowthPct

    FROM ComparableSalesDifference
)

SELECT
    Sales_2024,
    Sales_2025,
    Sales_Difference,
    YoYGrowthPct

FROM ComparableSalesGrowth;
GO 

select * from dbo.vw_ComparableSalesYoY




CREATE OR ALTER VIEW dbo.vw_YearlySalesComparison
AS
WITH YearlySales AS
(
    SELECT
        YEAR(orderdate) AS SalesYear,
        SUM(SalesAmount) AS TotalSales
    FROM dbo.FactSales
    GROUP BY YEAR(orderdate)
)
SELECT
    SalesYear,
    TotalSales,

    LAG(TotalSales) OVER (ORDER BY SalesYear)
        AS PreviousYearSales,

    CAST(
        (TotalSales - LAG(TotalSales) OVER (ORDER BY SalesYear))
        * 100.0
        / NULLIF(LAG(TotalSales) OVER (ORDER BY SalesYear), 0)
        AS DECIMAL(10,2)
    ) AS YoYGrowth

FROM YearlySales;
select * from dbo.vw_YearlySalesComparison