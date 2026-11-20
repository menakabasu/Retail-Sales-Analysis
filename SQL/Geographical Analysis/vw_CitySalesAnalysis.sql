Use Sales
CREATE OR ALTER VIEW vw_CitySalesAnalysis
AS

WITH CitySales AS
(
    SELECT
        dc.Country,
        dc.City,

        SUM(CASE
            WHEN fs.OrderDate >= '2023-01-01'
             AND fs.OrderDate < '2024-01-01'
            THEN fs.SalesAmount ELSE 0
        END) AS Sales_2023,

        SUM(CASE
            WHEN fs.OrderDate >= '2024-01-01'
             AND fs.OrderDate < '2025-01-01'
            THEN fs.SalesAmount ELSE 0
        END) AS Sales_2024,

        SUM(CASE
            WHEN fs.OrderDate >= '2025-01-01'
             AND fs.OrderDate < '2026-01-01'
            THEN fs.SalesAmount ELSE 0
        END) AS Sales_2025,

        SUM(fs.SalesAmount) AS TotalSales

    FROM FactSales fs

    INNER JOIN DimCustomers dc
        ON fs.CustomerID = dc.CustomerID

    WHERE fs.OrderDate >= '2023-01-01'
      AND fs.OrderDate < '2026-01-01'

    GROUP BY
        dc.Country,
        dc.City
)

SELECT
    Country,
    City,

    Sales_2023,
    Sales_2024,
    Sales_2025,
    TotalSales,

    -- Sales Gap
    Sales_2024 - Sales_2023 AS Gap_2024,

    Sales_2025 - Sales_2024 AS Gap_2025,

    -- Growth Percentage
    CAST(
        CASE
            WHEN Sales_2023 = 0 THEN NULL
            ELSE
                (Sales_2024 - Sales_2023)
                * 100.0 / Sales_2023
        END AS DECIMAL(10,2)
    ) AS GrowthPercentage_2024,

    CAST(
        CASE
            WHEN Sales_2024 = 0 THEN NULL
            ELSE
                (Sales_2025 - Sales_2024)
                * 100.0 / Sales_2024
        END AS DECIMAL(10,2)
    ) AS GrowthPercentage_2025,

    -- City Sales Contribution Percentage
    CAST(
        CASE
            WHEN SUM(TotalSales) OVER () = 0 THEN NULL
            ELSE
                TotalSales * 100.0
                / SUM(TotalSales) OVER ()
        END AS DECIMAL(10,2)
    ) AS CitySalesContributionPercentage

FROM CitySales;

select * from vw_CitySalesAnalysis

SELECT
    Country,
    City,
    TotalSales,
    CitySalesContributionPercentage,

    CASE
        WHEN CitySalesContributionPercentage >= 10
            THEN 'Very High Contribution'
        WHEN CitySalesContributionPercentage >= 5
            THEN 'High Contribution'
        WHEN CitySalesContributionPercentage >= 2
            THEN 'Moderate Contribution'
        ELSE 'Low Contribution'
    END AS CityImportance

FROM vw_CitySalesAnalysis
ORDER BY
    CitySalesContributionPercentage DESC;

    SELECT *
FROM dbo.vw_CitySalesAnalysis
ORDER BY TotalSales DESC;



CREATE OR ALTER VIEW dbo.vw_Top10CitySales
AS

WITH CityRanking AS
(
    SELECT
        Country,
        City,
        TotalSales,

        ROW_NUMBER() OVER
        (
            ORDER BY TotalSales DESC,
                     Country,
                     City
        ) AS CityRank

    FROM dbo.vw_CitySalesAnalysis
)

SELECT
    Country,
    City,
    TotalSales,
    CityRank

FROM CityRanking
WHERE CityRank <= 10;
GO
select * from dbo.vw_Top10CitySales