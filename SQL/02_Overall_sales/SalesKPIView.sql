

CREATE VIEW dbo.vw_Sales_KPI
AS
SELECT
    SUM(SalesAmount) AS TotalSales,
    COUNT(DISTINCT OrderID) AS TotalOrders,
    SUM(Quantity) AS TotalQuantity,
    COUNT(DISTINCT CustomerID) AS TotalCustomers,
    COUNT(DISTINCT ProductID) AS TotalProducts,
    AVG(SalesAmount) AS AverageOrderValue,
    AVG(UnitPrice) AS AverageUnitPrice
FROM dbo.FactSales;


SELECT *
FROM dbo.vw_Sales_KPI;