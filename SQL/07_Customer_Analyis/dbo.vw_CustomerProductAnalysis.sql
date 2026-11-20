USE Sales;
GO

CREATE OR ALTER VIEW 

AS

WITH CustomerProductSales AS
(
    SELECT
        YEAR(f.OrderDate) AS SalesYear,

        -- Customer
        f.CustomerID,
        CONCAT(c.FirstName, ' ', c.LastName) AS CustomerName,
        c.Country,
        c.City,

        -- Product
        f.ProductID,
        p.Name AS ProductName,
        p.Category,

        -- Sales
        SUM(f.SalesAmount) AS TotalSales,
        SUM(f.Quantity) AS TotalQuantity,
        COUNT(*) AS TotalOrders

    FROM dbo.FactSales AS f

    INNER JOIN dbo.DimCustomers AS c
        ON f.CustomerID = c.CustomerID

    INNER JOIN dbo.DimProducts AS p
        ON f.ProductID = p.ProductID

    GROUP BY
        YEAR(f.OrderDate),
        f.CustomerID,
        CONCAT(c.FirstName, ' ', c.LastName),
        c.Country,
        c.City,
        f.ProductID,
        p.Name,
        p.Category
)

SELECT
    SalesYear,

    CustomerID,
    CustomerName,
    Country,
    City,

    ProductID,
    ProductName,
    Category,

    TotalSales,
    TotalQuantity,
    TotalOrders,

    -- Product rank within each customer
    RANK() OVER
    (
        PARTITION BY CustomerID, SalesYear
        ORDER BY TotalSales DESC
    ) AS ProductRankWithinCustomer,

    -- Lowest-selling products within each customer
    RANK() OVER
    (
        PARTITION BY CustomerID, SalesYear
        ORDER BY TotalSales ASC
    ) AS LowProductRankWithinCustomer,


    -- Total sales of the customer
    SUM(TotalSales) OVER
    (
        PARTITION BY CustomerID, SalesYear
    ) AS CustomerTotalSales,

    -- Product contribution to customer's sales
    ROUND
    (
        TotalSales * 100.0 /
        NULLIF
        (
            SUM(TotalSales) OVER
            (
                PARTITION BY CustomerID, SalesYear
            ),
            0
        ),
        2
    ) AS ProductContributionToCustomerPct,

    -- Number of different products purchased
    COUNT(*) OVER
    (
        PARTITION BY CustomerID, SalesYear
    ) AS NumberOfProductsPurchased

FROM CustomerProductSales;
GO

SELECT TOP 10 *
FROM dbo.vw_CustomerProductAnalysis
ORDER BY
    CustomerID,
    SalesYear,
    ProductRankWithinCustomer;

    SELECT top 10 *
FROM dbo.vw_CustomerProductAnalysis
WHERE ProductRankWithinCustomer <= 3
ORDER BY
    CustomerID,
    SalesYear,
    ProductRankWithinCustomer;