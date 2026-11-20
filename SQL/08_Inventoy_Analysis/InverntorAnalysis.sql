
use Sales;
CREATE OR ALTER VIEW dbo.vw_ProductInventory
AS
SELECT
    ProductID,
    Name,
    Category,
    Brand,
    Stock,
    Availability
FROM dbo.DimProducts;


select * from vw_ProductInventory


select 
    availability,
    count(*) as ProductCount
from vw_ProductInventory
group by availability
order by ProductCount

--availability status of your product catalogue.--
select 
    availability,
    count(*) as ProductCount,
    count(*) * 100.0 /sum(count(*)) over() as PercentageofProducts
    from vw_ProductInventory

group by availability
order by PercentageofProducts desc

select 
    category,sum(stock) as TotalStocks
    from vw_ProductInventory
group by category
order by TotalStocks desc

SELECT
    Brand,
    SUM(Stock) AS TotalStock
FROM dbo.vw_ProductInventory
GROUP BY Brand
ORDER BY TotalStock DESC;

--Low-stock products--
SELECT
    ProductID,
    Name,
    Category,
    Brand,
    Stock,
    Availability
FROM dbo.vw_ProductInventory
WHERE Stock <= 10
ORDER BY Stock ASC;

--Available but low stock--
SELECT
    ProductID,
    Name,
    Category,
    Brand,
    Stock,
    Availability
FROM dbo.vw_ProductInventory
WHERE Availability IN ('Limited Stock', 'Out of Stock')
ORDER BY Stock ASC;