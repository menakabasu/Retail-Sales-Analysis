use Sales;
SELECT 'Total Sales' AS Business, SUM(SalesAmount) AS Value
FROM FactSales

UNION ALL

SELECT 'Average Order Value', AVG(SalesAmount)
FROM FactSales

UNION ALL

SELECT 'Total Quantity', SUM(Quantity)
FROM FactSales

UNION ALL

SELECT 'Total Orders', COUNT(DISTINCT OrderID)
FROM FactSales

UNION ALL

SELECT 'Total Customers', COUNT(DISTINCT CustomerID)
FROM FactSales

UNION ALL

SELECT 'Total Products', COUNT(DISTINCT ProductID)
FROM FactSales;

 
 
 

