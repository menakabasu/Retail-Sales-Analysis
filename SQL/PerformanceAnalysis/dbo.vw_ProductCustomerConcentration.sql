USE Sales;


CREATE OR ALTER VIEW dbo.vw_ProductCustomerConcentration
AS

WITH ProductCustomerSales AS
(
    SELECT
        YEAR(f.OrderDate) AS SalesYear,
        f.ProductID,
        p.Name AS ProductName,
        p.Category,
        f.CustomerID,
        CONCAT(c.FirstName, ' ', c.LastName) AS CustomerName,
        c.Country,
        c.City,
        SUM(f.SalesAmount) AS CustomerProductSales

    FROM dbo.FactSales AS f

    INNER JOIN dbo.DimCustomers AS c
        ON f.CustomerID = c.CustomerID

    INNER JOIN dbo.DimProducts AS p
        ON f.ProductID = p.ProductID

    GROUP BY
        YEAR(f.OrderDate),
        f.ProductID,
        p.Name,
        p.Category,
        f.CustomerID,
        CONCAT(c.FirstName, ' ', c.LastName),
        c.Country,
        c.City
),

ProductCustomerRank AS
(
    SELECT
        SalesYear,
        ProductID,
        ProductName,
        Category,
        CustomerID,
        CustomerName,
        Country,
        City,
        CustomerProductSales,

        SUM(CustomerProductSales) OVER
        (
            PARTITION BY ProductID, SalesYear
        ) AS ProductTotalSales,

        ROUND
        (
            CustomerProductSales * 100.0 /
            NULLIF
            (
                SUM(CustomerProductSales) OVER
                (
                    PARTITION BY ProductID, SalesYear
                ),
                0
            ),
            2
        ) AS CustomerContributionToProductPct,

        ROW_NUMBER() OVER
        (
            PARTITION BY ProductID, SalesYear
            ORDER BY CustomerProductSales DESC, CustomerID
        ) AS CustomerRankWithinProduct

    FROM ProductCustomerSales
)

SELECT *
FROM ProductCustomerRank
WHERE CustomerRankWithinProduct <= 10;
GO

SELECT
    YEAR(f.OrderDate) AS SalesYear,
    f.ProductID,
    p.Name AS ProductName,
    COUNT(DISTINCT f.CustomerID) AS NumberOfCustomers
FROM dbo.FactSales AS f
JOIN dbo.DimProducts AS p
    ON f.ProductID = p.ProductID
GROUP BY
    YEAR(f.OrderDate),
    f.ProductID,
    p.Name
HAVING COUNT(DISTINCT f.CustomerID) >= 3
ORDER BY
    SalesYear,
    ProductName;

    SELECT top 103 *
FROM dbo.vw_ProductCustomerConcentration
WHERE CustomerRankWithinProduct <= 3
ORDER BY
    SalesYear,
    ProductName,
    CustomerRankWithinProduct;

    SELECT
    SalesYear,
    ProductName,
    CustomerName,
    CustomerProductSales,
    ProductTotalSales,
    CustomerContributionToProductPct,
    CustomerRankWithinProduct
FROM dbo.vw_ProductCustomerConcentration
WHERE ProductName = 'Advanced Blender'
ORDER BY
    SalesYear,
    CustomerRankWithinProduct;