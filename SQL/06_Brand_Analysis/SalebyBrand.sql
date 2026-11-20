CREATE VIEW dbo.vw_Sales_ByBrand
AS
SELECT
    p.Brand,

    SUM(f.SalesAmount) AS TotalSales,

    SUM(f.Quantity) AS TotalQuantity,

    COUNT(DISTINCT f.OrderID) AS TotalOrders

FROM dbo.FactSales f

INNER JOIN dbo.DimProducts p
    ON f.ProductID = p.ProductID

GROUP BY
    p.Brand;

    SELECT *
FROM dbo.vw_Sales_ByBrand;

SELECT TOP 1 *
FROM dbo.vw_Sales_ByBrand
ORDER BY TotalSales DESC;

SELECT TOP 1 *
FROM dbo.vw_Sales_ByBrand
ORDER BY TotalQuantity DESC;

SELECT TOP 1 *
FROM dbo.vw_Sales_ByBrand
ORDER BY TotalOrders DESC;


