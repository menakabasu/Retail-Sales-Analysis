Use Sales
CREATE OR ALTER VIEW vw_CountrySalesAnalysis
AS

WITH CountrySales AS
(
    SELECT
        dc.Country,

        SUM(CASE
            WHEN fs.OrderDate >= '2023-01-01'
             AND fs.OrderDate < '2024-01-01'
            THEN fs.SalesAmount ELSE 0
        END) AS Sales_2023,

        SUM(CASE
            WHEN fs.OrderDate >= '2024-01-01'
             AND fs.OrderDate < '2024-07-01'
            THEN fs.SalesAmount ELSE 0
        END) AS Sales_2024,

        SUM(CASE
            WHEN fs.OrderDate >= '2025-01-01'
             AND fs.OrderDate < '2025-07-01'
            THEN fs.SalesAmount ELSE 0
        END) AS Sales_2025,

        SUM(fs.SalesAmount) AS TotalSales

    FROM FactSales fs

    INNER JOIN DimCustomers dc
        ON fs.CustomerID = dc.CustomerID

    WHERE fs.OrderDate >= '2023-01-01'
      AND fs.OrderDate < '2026-01-01'

    GROUP BY
        dc.Country
)

SELECT
    Country,
    Sales_2023,
    Sales_2024,
    Sales_2025,
    TotalSales,

    Sales_2024 - Sales_2023 AS Gap_2024,

    Sales_2025 - Sales_2024 AS Gap_2025,

    CAST(
    CASE
        WHEN Sales_2023 IS NULL OR Sales_2023 = 0
            THEN NULL

        WHEN Sales_2024 IS NULL OR Sales_2024 = 0
            THEN NULL

        ELSE
            (Sales_2024 - Sales_2023)
            * 100.0 / Sales_2023
    END AS DECIMAL(10,2)
) AS GrowthPercentage_2024,


CAST(
    CASE
        WHEN Sales_2024 IS NULL OR Sales_2024 = 0
            THEN NULL

        WHEN Sales_2025 IS NULL OR Sales_2025 = 0
            THEN NULL

        ELSE
            (Sales_2025 - Sales_2024)
            * 100.0 / Sales_2024
    END AS DECIMAL(10,2)
) AS GrowthPercentage_2025,

    CAST(
        TotalSales * 100.0 /
        NULLIF(SUM(TotalSales) OVER (), 0)
        AS DECIMAL(10,2)
    ) AS CountrySalesContributionPercentage,


    CASE
    WHEN (Sales_2024 IS NULL OR Sales_2024 = 0)
         AND (Sales_2025 IS NULL OR Sales_2025 = 0)
        THEN 'No Sales'

    WHEN (Sales_2024 IS NULL OR Sales_2024 = 0)
         AND Sales_2025 > 0
        THEN 'New Sales'

    WHEN Sales_2024 > 0
         AND (Sales_2025 IS NULL OR Sales_2025 = 0)
        THEN 'No Current Sales'

    WHEN Sales_2025 > Sales_2024
        THEN 'Growing'

    WHEN Sales_2025 < Sales_2024
        THEN 'Declining'

    ELSE 'No Significant Change'
END AS GrowthStatus
FROM CountrySales;

select top 10 * from vw_CountrySalesAnalysis

select top 10 country,totalsales from vw_CountrySalesAnalysis order by totalsales desc