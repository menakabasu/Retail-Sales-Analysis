use Sales
CREATE OR ALTER VIEW dbo.vw_BrandSalesGapRootCause
AS

WITH ProductComparison AS
(
    SELECT
        p.Brand,
        p.ProductID,
        p.Name,
        p.Category,
        p.Stock,
        p.Availability,

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

    FROM dbo.DimProducts p

    LEFT JOIN dbo.FactSales s
        ON p.ProductID = s.ProductID
        AND (
            (s.OrderDate >= '2024-01-01'
             AND s.OrderDate < '2024-07-01')
            OR
            (s.OrderDate >= '2025-01-01'
             AND s.OrderDate < '2025-07-01')
        )

    GROUP BY
        p.Brand,
        p.ProductID,
        p.Name,
        p.Category,
        p.Stock,
        p.Availability
),

ProductGaps AS
(
    SELECT
        *,
        H1_2025_Sales - H1_2024_Sales AS SalesGap,

        H1_2025_Quantity - H1_2024_Quantity
            AS QuantityGap,

        H1_2024_Sales / NULLIF(H1_2024_Quantity, 0)
            AS H1_2024_AveragePrice,

        H1_2025_Sales / NULLIF(H1_2025_Quantity, 0)
            AS H1_2025_AveragePrice

    FROM ProductComparison
)

SELECT
    *,

    CASE
        WHEN SalesGap >= 0
            THEN 'No Sales Decline'

        WHEN QuantityGap < 0
            THEN 'Lower Quantity Sold'

        WHEN H1_2025_AveragePrice < H1_2024_AveragePrice
            THEN 'Lower Average Selling Price'

        ELSE 'Further Investigation Required'
    END AS PossibleSalesFactor,

    CASE
        WHEN Availability = 'Out of Stock'
            THEN 'Check Stock Availability'

        WHEN Availability = 'Discontinued'
            THEN 'Review Discontinued Product'

        WHEN Availability = 'Backorder'
            THEN 'Review Backorder Status'

        ELSE 'No Current Stock Alert'
    END AS StockInvestigation

FROM ProductGaps;
select top 10 * from  dbo.vw_BrandSalesGapRootCause


-- SECTION 6: PRODUCT STOCK INVESTIGATION

SELECT
    Brand,
    ProductID,
    Name,
    SalesGap,
    QuantityGap,
    Stock,
    Availability,
    PossibleSalesFactor,
    StockInvestigation
FROM dbo.vw_BrandSalesGapRootCause
WHERE SalesGap < 0
ORDER BY Brand, SalesGap ASC;