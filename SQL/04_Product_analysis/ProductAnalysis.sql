
use Sales
create or alter view dbo.vw_ProductSales
as
select
 p.name as productName,
 p.productid as ProductId,
 sum(f.salesamount) as TotalSales,
 sum(f.quantity) as TotalQuantity,
 count(distinct f.orderid) as TotalOrders
from dbo.factsales f
inner join dbo.dimproducts p
on f.productid=p.productid
group by
p.productid,
p.name

select * from dbo.vw_ProductSales order by ProductId,productName


-- 1. Top products by sales
SELECT TOP 10
    ProductName,
    TotalSales
FROM dbo.vw_ProductSales
ORDER BY TotalSales DESC;


-- 2. Top products by quantity
SELECT TOP 10
    ProductName,
    TotalQuantity
FROM dbo.vw_ProductSales
ORDER BY TotalQuantity DESC;


-- 3. Orders by product
SELECT TOP 10
    ProductName,
    TotalOrders
FROM dbo.vw_ProductSales
ORDER BY TotalOrders DESC;

