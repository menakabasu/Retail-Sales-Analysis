use Sales;

CREATE VIEW dbo.vw_CustomerSales
AS
SELECT
    c.CustomerID,
    c.FirstName,
    c.LastName,
    c.FirstName + ' ' + c.LastName AS CustomerName,

    SUM(f.SalesAmount) AS TotalSales,

    COUNT(DISTINCT f.OrderID) AS TotalOrders,

    SUM(f.Quantity) AS TotalQuantity,

    AVG(f.SalesAmount) AS AverageOrderValue

FROM dbo.FactSales f

JOIN dbo.DimCustomers c
    ON f.CustomerID = c.CustomerID

GROUP BY
    c.CustomerID,
    c.FirstName,
    c.LastName;

    SELECT *
FROM dbo.vw_CustomerSales;

SELECT TOP 10
    CustomerID,
    CustomerName,
    TotalSales
FROM dbo.vw_CustomerSales
ORDER BY TotalSales DESC;

SELECT TOP 10
    CustomerID,
    CustomerName,
    TotalOrders
FROM dbo.vw_CustomerSales
ORDER BY TotalOrders DESC;

SELECT TOP 10
    CustomerID,
    CustomerName,
    TotalQuantity
FROM dbo.vw_CustomerSales
ORDER BY TotalQuantity DESC;

SELECT TOP 10
    CustomerID,
    CustomerName,
    TotalOrders,
    TotalSales,
    AverageOrderValue
FROM dbo.vw_CustomerSales
ORDER BY AverageOrderValue DESC;