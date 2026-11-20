use Sales
select 'Customers' as TableName ,count(*) as Row_Count 
from dbo.factSales

UNION ALL

SELECT 'Products', COUNT(*)
FROM dbo.Dimproducts

UNION ALL

SELECT 'Sales', COUNT(*)
FROM dbo.factsales;

SELECT
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME IN
(
    'DimCustomers',
    'DimProducts',
    'FactSales'
)
ORDER BY TABLE_NAME, ORDINAL_POSITION;

--Check CustomerID
select customerID,count(*) as NumberOfCustomers from dimcustomers
group by customerid having count(*)>1

--Check ProductID--
SELECT
    ProductID,
    COUNT(*) AS NumberOfRows
FROM dbo.dimproducts
GROUP BY ProductID
HAVING COUNT(*) > 1;
--Chck orderID--
SELECT
    OrderID,
    COUNT(*) AS NumberOfRows
FROM dbo.factsales
GROUP BY OrderID
HAVING COUNT(*) > 1;

--Creating ForEign Keys --

Alter table factsales
add constraint FK_SALES_CUSTOMER
foreign key (customerid)
references dimcustomers(customerid);

Alter table factsales
add constraint FK_SALES_PRODUCT
foreign key (productid)
references dimproducts(productid);
--Now we need to make sure every Sales customer actually exists in Customers.--
Select distinct s.CustomerID from factsales s
left join dimcustomers c
on s.CustomerID =c.CustomerID
where c.CustomerID  is null
--Check ProductID--
SELECT DISTINCT s.ProductID
FROM dbo.factsales s
LEFT JOIN dbo.dimproducts p
    ON s.ProductID = p.ProductID
WHERE p.ProductID IS NULL;
--Check NULL Customer IDs --
select count(*) as NullCustomerIds
from factsales where customerid is null
--Check NULL Product IDs--
SELECT COUNT(*) AS NullProductIDs
FROM dbo.factsales
WHERE ProductID IS NULL;
--Check negative sales--
SELECT COUNT(*) AS NullQuantities
FROM dbo.factsales
WHERE Quantity IS NULL;

SELECT COUNT(*) AS NegativeSales
FROM dbo.factsales
WHERE SalesAmount < 0;
--Check dates--

SELECT
    MIN(OrderDate) AS FirstOrderDate,
    MAX(OrderDate) AS LastOrderDate
FROM dbo.factsales;