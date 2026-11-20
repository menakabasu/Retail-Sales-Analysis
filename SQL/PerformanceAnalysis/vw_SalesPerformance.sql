USE Sales;
GO

CREATE OR ALTER VIEW dbo.vw_SalesPerformance
AS
SELECT
    COUNT(DISTINCT fs.OrderID) AS TotalOrders,
    COUNT(DISTINCT fs.CustomerID) AS TotalCustomers,
    SUM(fs.SalesAmount) AS TotalSales,
    SUM(fs.Quantity) AS TotalQuantity,

    CAST(
        SUM(fs.SalesAmount) * 1.0
        / NULLIF(COUNT(DISTINCT fs.OrderID), 0)
        AS DECIMAL(18,2)
    ) AS AverageOrderValue,

    CAST(
        SUM(fs.Quantity) * 1.0
        / NULLIF(COUNT(DISTINCT fs.OrderID), 0)
        AS DECIMAL(18,2)
    ) AS AverageQuantityPerOrder

FROM dbo.FactSales fs;
GO

SELECT *
FROM dbo.vw_SalesPerformance;

/*This answers:

How much did we sell?
How many orders?
How many customers?
How many units?
What is the average order value?
How many units are sold per order? */