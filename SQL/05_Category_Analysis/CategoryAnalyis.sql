
use Sales;
CREATE VIEW dbo.vw_Sales_ByCategory
AS
SELECT
    p.Category,

    SUM(f.SalesAmount) AS TotalSales,

    SUM(f.Quantity) AS TotalQuantity,

    COUNT(DISTINCT f.OrderID) AS TotalOrders

FROM dbo.FactSales f

INNER JOIN dbo.DimProducts p
    ON f.ProductID = p.ProductID

GROUP BY
    p.Category;


SELECT *
FROM dbo.vw_Sales_ByCategory;

SELECT TOP 1 *
FROM dbo.vw_Sales_ByCategory
ORDER BY TotalSales DESC;

SELECT TOP 1 *
FROM dbo.vw_Sales_ByCategory
ORDER BY TotalQuantity DESC;

SELECT TOP 1 *
FROM dbo.vw_Sales_ByCategory
ORDER BY TotalOrders DESC;