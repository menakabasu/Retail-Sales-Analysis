Use Sales

CREATE OR ALTER VIEW vw_GeographicalDeclineRootCause
AS

WITH GeographicalProductSales AS
(
    SELECT
        dc.Country,
        dc.City,
        dp.ProductID,
        dp.Name AS ProductName,
        dp.Category,

        -- 2023 Full Year Sales
        SUM(CASE
            WHEN fs.OrderDate >= '2023-01-01'
             AND fs.OrderDate < '2024-01-01'
            THEN fs.SalesAmount ELSE 0
        END) AS Sales_2023,

        -- 2024 Full Year Sales
        SUM(CASE
            WHEN fs.OrderDate >= '2024-01-01'
             AND fs.OrderDate < '2025-01-01'
            THEN fs.SalesAmount ELSE 0
        END) AS Sales_2024,

        -- 2025 Sales
        SUM(CASE
            WHEN fs.OrderDate >= '2025-01-01'
             AND fs.OrderDate < '2026-01-01'
            THEN fs.SalesAmount ELSE 0
        END) AS Sales_2025,

        -- 2023 Quantity
        SUM(CASE
            WHEN fs.OrderDate >= '2023-01-01'
             AND fs.OrderDate < '2024-01-01'
            THEN fs.Quantity ELSE 0
        END) AS Quantity_2023,

        -- 2024 Quantity
        SUM(CASE
            WHEN fs.OrderDate >= '2024-01-01'
             AND fs.OrderDate < '2025-01-01'
            THEN fs.Quantity ELSE 0
        END) AS Quantity_2024,

        -- 2025 Quantity
        SUM(CASE
            WHEN fs.OrderDate >= '2025-01-01'
             AND fs.OrderDate < '2026-01-01'
            THEN fs.Quantity ELSE 0
        END) AS Quantity_2025

    FROM FactSales fs

    INNER JOIN DimCustomers dc
        ON fs.CustomerID = dc.CustomerID

    INNER JOIN DimProducts dp
        ON fs.ProductID = dp.ProductID

    WHERE fs.OrderDate >= '2023-01-01'
      AND fs.OrderDate < '2026-01-01'

    GROUP BY
        dc.Country,
        dc.City,
        dp.ProductID,
        dp.Name,
        dp.Category
),

ProductSalesGap AS
(
    SELECT
        *,

        Sales_2024 - Sales_2023 AS SalesGap_2024,

        Sales_2025 - Sales_2024 AS SalesGap_2025,

        Quantity_2024 - Quantity_2023 AS QuantityGap_2024,

        Quantity_2025 - Quantity_2024 AS QuantityGap_2025

    FROM GeographicalProductSales
)

SELECT
    Country,
    City,
    ProductID,
    ProductName,
    Category,

    Sales_2023,
    Sales_2024,
    Sales_2025,

    SalesGap_2024,
    SalesGap_2025,

    CAST(
        CASE
            WHEN Sales_2023 = 0 THEN NULL
            ELSE SalesGap_2024 * 100.0 / Sales_2023
        END AS DECIMAL(10,2)
    ) AS GrowthPercentage_2024,

    CAST(
        CASE
            WHEN Sales_2024 = 0 THEN NULL
            ELSE SalesGap_2025 * 100.0 / Sales_2024
        END AS DECIMAL(10,2)
    ) AS GrowthPercentage_2025,

    Quantity_2023,
    Quantity_2024,
    Quantity_2025,

    QuantityGap_2024,
    QuantityGap_2025

FROM ProductSalesGap

WHERE
    SalesGap_2024 < 0
    OR SalesGap_2025 < 0;

    select * from vw_GeographicalDeclineRootCause