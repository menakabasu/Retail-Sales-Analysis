
use Sales
Go
create or alter view dbo.vw_InventorySalesAnalysis as 
With LatestYear as 
(
	select max(year(orderdate)) as SaleYear from dbo.FactSales
),

ProductSales as 
(

	select 
		f.productid,
		
	sum(f.quantity) as TotalQuantitySold,
	sum(f.salesamount) as TotalSales
	from dbo.factsales as f 
	group by f.ProductID
),








LatestYearsales as(

	select 

	max(year(f.orderdate)) as Year,
	f.productid,
	sum(f.quantity) as LatestYearQuantity,
	sum(f.salesamount) as LatestTotalSales
	from dbo.factsales as f 
	cross join LatestYear as LY
	where year(f.orderdate)=LY.SaleYear
	group by f.ProductID



),


Productanalysis as
(
	select
		p.productid,
		p.name as ProductName,
		p.category,
		p.stock as Stock,
		p.availability ,
		
		coalesce(ps.TotalQuantitySold ,0) as TotalQuantitySold,
		coalesce(ps.TotalSales,0) as TotalSales,
		coalesce(lys.LatestYearQuantity,0) as LatestYearQuantitySold,

		coalesce(lys.LatestTotalSales,0) as LatestTotalSales
	

	from dbo.dimproducts p 
	left join ProductSales ps
	on p.productid=ps.productid
	left join LatestYearsales lys
	on p.productid=lys.productid





),

ProductanalysiswithStock as
(
	select *,avg(cast(Stock as decimal)) over() as AvgStock,
	avg(cast(LatestYearQuantitySold as decimal)) over() as AvgLatestYearQuantitySold
	from Productanalysis

)

SELECT
    *,
    CASE
        WHEN Stock IS NULL
            THEN 'Stock Data Missing'

        WHEN Availability = 'Discontinued'
            THEN 'Discontinued - Review Separately'

        WHEN Availability = 'Out of Stock'
             AND Stock > 0
            THEN 'Verify Stock and Availability'

        WHEN Availability = 'Out of Stock'
            THEN 'Out of Stock - Check Demand'

        WHEN Availability = 'Backorder'
            THEN 'Backorder - Review Supply'

        WHEN Availability = 'Pre-order'
            THEN 'Pre-order - Review Separately'

        WHEN Availability = 'Limited Stock'
            THEN 'Limited Stock - Check Demand'

        WHEN Availability = 'In Stock'
             AND Stock <= 0
            THEN 'Verify Stock and Availability'

        -- High stock + low latest-year sales
        WHEN Stock >= AvgStock
             AND LatestYearQuantitySold
                 < AvgLatestYearQuantitySold
            THEN 'Review Excess Stock'

        -- Low stock + high latest-year sales
        WHEN Stock < AvgStock
             AND LatestYearQuantitySold
                 > AvgLatestYearQuantitySold
            THEN 'Consider Replenishment'

        -- High stock + high latest-year sales
        WHEN Stock >= AvgStock
             AND LatestYearQuantitySold
                 >= AvgLatestYearQuantitySold
            THEN 'Monitor Stock Levels'

        ELSE 'Review Demand'
    END AS InventoryRecommendation

FROM ProductanalysiswithStock;
GO




select top 30 * from dbo.vw_InventorySalesAnalysis


SELECT
    Availability,
    COUNT(*) AS ProductCount
FROM dbo.DimProducts
GROUP BY Availability
ORDER BY ProductCount DESC;


SELECT
    ProductID,
    Name AS ProductName,
    Stock,
    Availability,
    CASE
        WHEN Availability = 'Discontinued'
            THEN 'Discontinued Product'

        WHEN Availability = 'Out of Stock'
             AND Stock > 0
            THEN 'Check Stock and Availability'

        WHEN Availability = 'In Stock'
             AND (Stock IS NULL OR Stock <= 0)
            THEN 'Check Stock and Availability'

        WHEN Availability = 'Limited Stock'
             AND Stock = 0
            THEN 'Check Stock and Availability'

        ELSE 'No Issue Identified by These Rules'
    END AS StockAvailabilityCheck
FROM dbo.DimProducts
ORDER BY Availability, ProductID;



SELECT
    Availability,
    StockAvailabilityCheck,
    COUNT(*) AS ProductCount
FROM
(
    SELECT
        Availability,
        CASE
            WHEN Stock IS NULL
                THEN 'Stock Value Missing'

            WHEN Availability = 'Out of Stock'
                 AND Stock > 0
                THEN 'Check Stock and Availability'

            WHEN Availability = 'In Stock'
                 AND Stock <= 0
                THEN 'Check Stock and Availability'

            WHEN Availability = 'Limited Stock'
                 AND Stock = 0
                THEN 'Check Stock and Availability'

            WHEN Availability = 'Discontinued'
                THEN 'Discontinued Product'

            ELSE 'No Issue Identified by These Rules'
        END AS StockAvailabilityCheck
    FROM dbo.DimProducts
) AS ProductCheck
GROUP BY
    Availability,
    StockAvailabilityCheck
ORDER BY
    Availability,
    StockAvailabilityCheck;

SELECT
    ProductID,
    Name AS ProductName,
    Stock,
    Availability
FROM dbo.DimProducts
WHERE Availability = 'Out of Stock'
  AND Stock > 0
ORDER BY Stock DESC;

SELECT
    p.ProductID,
    p.Name AS ProductName,
    p.Stock,
    p.Availability,
    COALESCE(SUM(f.Quantity), 0) AS TotalQuantitySold,
    COALESCE(SUM(f.SalesAmount), 0) AS TotalSales
FROM dbo.DimProducts AS p
LEFT JOIN dbo.FactSales AS f
    ON p.ProductID = f.ProductID
WHERE p.Availability = 'Out of Stock'
GROUP BY
    p.ProductID,
    p.Name,
    p.Stock,
    p.Availability
ORDER BY TotalSales DESC;

WITH ProductSales AS
(
    SELECT
        ProductID,
        SUM(Quantity) AS TotalQuantitySold,
        SUM(SalesAmount) AS TotalSales
    FROM dbo.FactSales
    GROUP BY ProductID
)


SELECT top 10 *
FROM dbo.vw_InventorySalesAnalysis
ORDER BY ProductID;


CREATE OR ALTER VIEW dbo.vw_InventoryAnalysisComplete
AS
WITH ProductSales AS
(
    SELECT
        p.ProductID,
        p.Category,
        p.Stock,
        p.Availability,
        COALESCE(SUM(fs.Quantity), 0) AS TotalQuantitySold,
        COALESCE(SUM(fs.SalesAmount), 0) AS TotalSales
    FROM dbo.DimProducts AS p
    LEFT JOIN dbo.FactSales AS fs
        ON p.ProductID = fs.ProductID
    GROUP BY
        p.ProductID,
        p.Category,
        p.Stock,
        p.Availability
),
InventoryBenchmarks AS
(
    SELECT
        AVG(CAST(Stock AS decimal(10,2))) AS AvgStock,
        AVG(CAST(TotalSales AS FLOAT)) AS AvgProductSales,
        AVG(CAST(TotalQuantitySold AS FLOAT))
            AS AvgQuantitySold
    FROM ProductSales
)
SELECT
    ps.ProductID,
    ps.Category,
    ps.Stock,
    ps.Availability,
    ps.TotalQuantitySold,
    ps.TotalSales,
    b.AvgStock,
    b.AvgProductSales,
    b.AvgQuantitySold,

    CASE
        WHEN ps.Availability = 'Out of Stock'
            THEN 'Out of Stock'
        WHEN ps.Availability = 'Limited Stock'
            THEN 'Limited Stock'
        ELSE 'Other Availability'
    END AS InventoryRisk,

    CASE
        WHEN ps.Stock > b.AvgStock
         AND ps.TotalSales < b.AvgProductSales
            THEN 'High Stock - Low Sales'
        ELSE 'Other'
    END AS StockSalesAnalysis,

    CASE
        WHEN ps.TotalQuantitySold > b.AvgQuantitySold
         AND ps.Stock <= b.AvgStock
            THEN 'High Sales - Low Stock'
        ELSE 'Other'
    END AS ReplenishmentReview,

    CASE
        WHEN ps.Availability = 'Discontinued'
         AND ps.TotalSales > 0
            THEN 'Discontinued Product with Sales'
        WHEN ps.Availability = 'Discontinued'
         AND ps.TotalSales = 0
            THEN 'Discontinued Product with No Sales'
        ELSE 'Not Discontinued'
    END AS DiscontinuedSalesStatus,

    CASE
        WHEN ps.Availability = 'Out of Stock'
            THEN 'Review replenishment and product demand'
        WHEN ps.Availability = 'Limited Stock'
            THEN 'Review stock levels and recent sales'
        WHEN ps.Availability = 'Discontinued'
         AND ps.TotalSales > 0
            THEN 'Check whether remaining sales are expected'
        WHEN ps.Stock > b.AvgStock
         AND ps.TotalSales < b.AvgProductSales
            THEN 'Review demand before replenishing stock'
        WHEN ps.TotalQuantitySold > b.AvgQuantitySold
         AND ps.Stock <= b.AvgStock
            THEN 'Review whether replenishment is needed'
        ELSE 'Monitor inventory and sales'
    END AS RecommendedAction

FROM ProductSales AS ps
CROSS JOIN InventoryBenchmarks AS b;

SELECT top 10 *
FROM dbo.vw_InventoryAnalysisComplete
ORDER BY ProductID;


SELECT
    ProductID,
    TotalQuantitySold,
    LatestYearQuantitySold,
    LatestTotalSales
FROM dbo.vw_InventorySalesAnalysis
WHERE LatestYearQuantitySold = 0
ORDER BY TotalQuantitySold DESC;


SELECT
    Availability,
    COUNT(*) AS ProductCount
FROM dbo.vw_InventorySalesAnalysis
where Availability = 'Out of Stock'
GROUP BY Availability
ORDER BY ProductCount DESC;

SELECT
    COUNT(*) AS TotalProducts,

    SUM(CASE
        WHEN Availability = 'Discontinued' THEN 1
        ELSE 0
    END) AS DiscontinuedProducts,

    SUM(CASE
        WHEN Availability = 'Out of Stock' THEN 1
        ELSE 0
    END) AS OutOfStockProducts

FROM dbo.vw_InventorySalesAnalysis;


SELECT
    ProductID,
    COUNT(*) AS Row_Count
FROM dbo.vw_InventorySalesAnalysis
GROUP BY ProductID
HAVING COUNT(*) > 1;


SELECT
    Availability,
    COUNT(*) AS ProductCount
FROM dbo.vw_InventorySalesAnalysis
GROUP BY Availability
ORDER BY ProductCount DESC;



SELECT
    ProductID,
    ProductName,
    Category,
    Stock,
    Availability,
    TotalQuantitySold,
    LatestYearQuantitySold,
    InventoryRecommendation
FROM dbo.vw_InventorySalesAnalysis
WHERE InventoryRecommendation IN
(
    'Verify Stock and Availability',
    'Out of Stock - Check Demand',
    'Backorder - Review Supply',
    'Limited Stock - Check Demand',
    'Review Excess Stock',
    'Consider Replenishment',
    'Discontinued - Review Separately',
    'Pre-order - Review Separately',
    'Stock Data Missing',
    'Verify Negative Stock'
)
ORDER BY Availability, Stock DESC;


SELECT
    COUNT(*) AS TotalProducts,
    SUM(CASE WHEN Availability = 'Discontinued'
             THEN 1 ELSE 0 END) AS DiscontinuedProducts,
    SUM(CASE WHEN Availability = 'Out of Stock'
             THEN 1 ELSE 0 END) AS OutOfStockProducts
FROM dbo.vw_InventorySalesAnalysis;


SELECT
    ProductID,
    ProductName,
    Category,
    Stock,
    TotalQuantitySold,
    LatestYearQuantitySold,
    Availability,
    InventoryRecommendation
FROM dbo.vw_InventorySalesAnalysis
ORDER BY Stock DESC;


SELECT
    ProductID,
    ProductName,
    Category,
    Stock,
    LatestYearQuantitySold,
    Availability,
    InventoryRecommendation
FROM dbo.vw_InventorySalesAnalysis
WHERE Stock > AvgStock
  AND LatestYearQuantitySold < AvgLatestYearQuantitySold
ORDER BY Stock DESC;


CREATE OR ALTER VIEW dbo.vw_ProductActionList
AS
SELECT
    ProductID,
    ProductName,
    Category,
    Stock,
    LatestYearQuantitySold,
    Availability,

    CASE
        WHEN Stock IS NULL
            THEN 'Verify Stock Data'

        WHEN Availability = 'Discontinued'
            THEN 'Review Discontinued Product'

        WHEN Availability = 'Out of Stock'
             AND Stock > 0
            THEN 'Verify Stock and Availability'

        WHEN Availability = 'Out of Stock'
            THEN 'Investigate Stock Availability'

        WHEN Availability = 'Backorder'
            THEN 'Review Supplier Supply'

        WHEN Availability = 'Pre-order'
            THEN 'Review Pre-order Status'

        WHEN Availability = 'Limited Stock'
            THEN 'Monitor Stock Availability'

        WHEN InventoryRecommendation = 'Review Excess Stock'
            THEN 'Investigate Excess Stock'

        WHEN InventoryRecommendation = 'Consider Replenishment'
            THEN 'Review Replenishment'

        WHEN InventoryRecommendation = 'Verify Stock and Availability'
            THEN 'Verify Inventory Records'

        WHEN InventoryRecommendation = 'Review Demand'
            THEN 'Investigate Product Demand'

        ELSE 'Monitor Product'
    END AS RecommendedAction

FROM dbo.vw_InventorySalesAnalysis;
GO


SELECT
    ProductID,
    ProductName,
    Category,
    Stock,
    LatestYearQuantitySold,
    Availability,
    RecommendedAction
FROM dbo.vw_ProductActionList
WHERE RecommendedAction <> 'Monitor Product'
ORDER BY RecommendedAction, Stock DESC;


SELECT
    COUNT(CASE
        WHEN Stock > AvgStock
         AND LatestYearQuantitySold < AvgLatestYearQuantitySold
        THEN 1
    END) AS [High Stock / Low Sales],

    COUNT(CASE
        WHEN (Availability = 'Out of Stock' AND Stock > 0)
          OR (Availability = 'In Stock' AND Stock <= 0)
        THEN 1
    END) AS [Stock Conflicts],

    COUNT(CASE
        WHEN Stock < AvgStock
         AND LatestYearQuantitySold > AvgLatestYearQuantitySold
        THEN 1
    END) AS [Replenishment Candidates]

FROM dbo.vw_InventorySalesAnalysis;