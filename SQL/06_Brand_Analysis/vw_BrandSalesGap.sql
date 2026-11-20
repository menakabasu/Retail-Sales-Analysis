Use Sales
CREATE OR ALTER VIEW dbo.vw_BrandSalesGap
AS

WITH BrandSales AS
(
    SELECT
        p.Brand,

        SUM(CASE
            WHEN s.OrderDate >= '2024-01-01'
             AND s.OrderDate < '2024-07-01'
            THEN s.SalesAmount
            ELSE 0
        END) AS H1_2024_Sales,

        SUM(CASE
            WHEN s.OrderDate >= '2025-01-01'
             AND s.OrderDate < '2025-07-01'
            THEN s.SalesAmount
            ELSE 0
        END) AS H1_2025_Sales

    FROM dbo.FactSales AS s
    INNER JOIN dbo.DimProducts AS p
        ON s.ProductID = p.ProductID

    WHERE
        (s.OrderDate >= '2024-01-01'
         AND s.OrderDate < '2024-07-01')
        OR
        (s.OrderDate >= '2025-01-01'
         AND s.OrderDate < '2025-07-01')

    GROUP BY
        p.Brand
)

SELECT
    Brand,
    H1_2024_Sales,
    H1_2025_Sales,

    H1_2025_Sales - H1_2024_Sales
        AS SalesGap,

    CAST(
        (H1_2025_Sales - H1_2024_Sales)
        * 100.0 /
        NULLIF(H1_2024_Sales, 0)
        AS DECIMAL(10,2)
    ) AS SalesGrowthPercentage,

    CASE
        WHEN H1_2025_Sales > H1_2024_Sales
            THEN 'Growing'

        WHEN H1_2025_Sales < H1_2024_Sales
            THEN 'Declining'

        ELSE 'Stable'
    END AS BrandStatus

FROM BrandSales;


select * from dbo.vw_BrandSalesGap



WITH ProductRanking AS
(
    SELECT
        Brand,
        ProductID,
        Name,
        H1_2024_Sales,
        H1_2025_Sales,
        SalesGap,
        QuantityGap,

        ROW_NUMBER() OVER
        (
            PARTITION BY Brand
            ORDER BY SalesGap ASC
        ) AS ProductRank

    FROM dbo.vw_BrandSalesGapProductDetails
    WHERE SalesGap < 0
)

SELECT
    Brand,
    ProductID,
    Name,
    H1_2024_Sales,
    H1_2025_Sales,
    SalesGap,
    QuantityGap,
    ProductRank
FROM ProductRanking
WHERE ProductRank <= 5
ORDER BY Brand, ProductRank;


SELECT
    COUNT(*) AS TotalBrands,

    SUM(CASE
        WHEN SalesGap < 0 THEN 1
        ELSE 0
    END) AS DecliningBrands,

    SUM(CASE
        WHEN SalesGap > 0 THEN 1
        ELSE 0
    END) AS GrowingBrands,

    SUM(SalesGap) AS TotalSalesGap

FROM dbo.vw_BrandSalesGap;