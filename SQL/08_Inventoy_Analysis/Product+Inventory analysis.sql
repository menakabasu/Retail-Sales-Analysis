
use Sales;

CREATE VIEW vw_ProductSalesInventory
AS
SELECT
    p.productid,
    p.Name,
    p.Category,
    p.Brand,
    p.Stock,
    p.Availability,

    COALESCE(SUM(s.SalesAmount), 0) AS TotalSales,
    COALESCE(SUM(s.Quantity), 0) AS QuantitySold,
    COUNT(DISTINCT s.OrderID) AS TotalOrders

FROM DimProducts p

LEFT JOIN FactSales s
    ON p.ProductID = s.ProductID

GROUP BY
    p.ProductID,
    p.Name,
    p.Category,
    p.Brand,
    p.Stock,
    p.Availability;

    SELECT
    Name,
    Stock,
    TotalSales,
    QuantitySold
FROM vw_ProductSalesInventory
ORDER BY TotalSales DESC;

--Sales vs Stock--
SELECT
    Name,
    Stock,
    TotalSales,
    QuantitySold
FROM vw_ProductSalesInventory
ORDER BY TotalSales DESC;


SELECT
    Name,
    Stock,
    QuantitySold,
    Stock - QuantitySold AS StockVsSold
FROM vw_ProductSalesInventory
ORDER BY StockVsSold;


SELECT
    Name,
    TotalSales,
    QuantitySold,
    Stock
FROM vw_ProductSalesInventory
ORDER BY TotalSales DESC;


SELECT
    Name,
    TotalSales,
    QuantitySold,
    Stock
FROM vw_ProductSalesInventory
ORDER BY TotalSales ASC;

SELECT
    ProductID,
    Name,
    Category,
    Brand,
    Stock,
    Availability
FROM vw_ProductSalesInventory
WHERE TotalSales = 0;

SELECT
    Name,
    Stock,
    QuantitySold,
    TotalSales
FROM vw_ProductSalesInventory
WHERE Stock > 50
  AND QuantitySold < 10
ORDER BY Stock DESC;

SELECT
    Name,
    Stock,
    QuantitySold,
    TotalSales
FROM vw_ProductSalesInventory
WHERE Stock < 20
  AND QuantitySold > 50
ORDER BY QuantitySold DESC;