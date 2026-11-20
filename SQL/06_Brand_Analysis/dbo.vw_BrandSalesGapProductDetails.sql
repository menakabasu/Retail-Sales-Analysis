use Sales
CREATE OR ALTER VIEW dbo.vw_BrandSalesGapProductDetails
AS

WITH ProductSales AS
(
    SELECT
        p.Brand,
        p.ProductID,
        p.Name,
        p.Category,

        SUM(CASE
            WHEN s.OrderDate >= '2024-01-01'
             AND s.OrderDate < '2024-07-01'
            THEN s.SalesAmount ELSE 0
        END) AS H1_2024_Sales,

        SUM(CASE
            WHEN s.OrderDate >= '2025-01-01'
             AND s.OrderDate < '2025-07-01'
            THEN s.SalesAmount ELSE 0
        END) AS H1_2025_Sales,

        SUM(CASE
            WHEN s.OrderDate >= '2024-01-01'
             AND s.OrderDate < '2024-07-01'
            THEN s.Quantity ELSE 0
        END) AS H1_2024_Quantity,

        SUM(CASE
            WHEN s.OrderDate >= '2025-01-01'
             AND s.OrderDate < '2025-07-01'
            THEN s.Quantity ELSE 0
        END) AS H1_2025_Quantity

    FROM dbo.FactSales s
    INNER JOIN dbo.DimProducts p
        ON s.ProductID = p.ProductID

    WHERE
        (s.OrderDate >= '2024-01-01'
         AND s.OrderDate < '2024-07-01')
        OR
        (s.OrderDate >= '2025-01-01'
         AND s.OrderDate < '2025-07-01')

    GROUP BY
        p.Brand,
        p.ProductID,
        p.Name,
        p.Category
)

SELECT
    *,
    H1_2025_Sales - H1_2024_Sales AS SalesGap,

    CAST(
        (H1_2025_Sales - H1_2024_Sales)
        * 100.0 / NULLIF(H1_2024_Sales, 0)
        AS DECIMAL(10,2)
    ) AS SalesGrowthPercentage,

    H1_2025_Quantity - H1_2024_Quantity
        AS QuantityGap

FROM ProductSales;
select * from dbo.vw_BrandSalesGapProductDetails


select brand,name,salesgap,quantitygap from dbo.vw_BrandSalesGapProductDetails where salesgap<0 order by salesgap 