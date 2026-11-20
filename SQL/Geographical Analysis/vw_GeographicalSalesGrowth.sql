
Use Sales


CREATE OR ALTER VIEW vw_GeographicalSalesGrowth
AS

WITH GeographicalSales AS
(
    -- Country-level performance
    SELECT
        'Country' AS GeographyLevel,
        Country,
        CAST(NULL AS NVARCHAR(150)) AS City,
        Sales_2023,

        Sales_2024,
        Sales_2025,
        TotalSales

    FROM vw_CountrySalesAnalysis

    UNION ALL

    -- City-level performance
    SELECT
        'City' AS GeographyLevel,
        Country,
        City,
        Sales_2023,
        Sales_2024,
        Sales_2025,
        TotalSales

    FROM vw_CitySalesAnalysis
)

SELECT
    GeographyLevel,
    Country,
    City,
    Sales_2023,
    Sales_2024,
    Sales_2025,

    Sales_2024 - Sales_2023 AS Gap_2024,

    Sales_2025 - Sales_2024 AS Gap_2025,

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

    TotalSales,

    CAST(
        CASE
            WHEN SUM(TotalSales) OVER () = 0 THEN NULL
            ELSE
                TotalSales * 100.0
                / SUM(TotalSales) OVER ()
        END AS DECIMAL(10,2)
    ) AS SalesContributionPercentage


     CASE
        WHEN Gap_2025 > 0 THEN 'Growing'
        WHEN Gap_2025 < 0 THEN 'Declining'
        ELSE 'No Change'
    END AS GrowthStatus

FROM GeographicalSales;

select * from vw_GeographicalSalesGrowth