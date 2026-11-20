USE Sales;
GO
create or alter view dbo.vw_monthlyproductsaleanalysis as

WITH MonthlySales AS
(
    SELECT
        p.productid as productid,
        p.name as ProductName,
        YEAR(OrderDate) AS SalesYear,
        MONTH(OrderDate) AS SalesMonth,
        SUM(SalesAmount) AS TotalSales
    FROM dbo.FactSales f
    inner join dbo.DimProducts p
    on f.ProductID =p.ProductID

    WHERE OrderDate >= '2024-01-01'
      AND OrderDate <  '2026-01-01'
    GROUP BY
        YEAR(OrderDate),
        MONTH(OrderDate),
        p.productid,
        p.name
),
MonthComparison as
(
    select
         ProductID,
        ProductName,
        SalesMonth,

       
        SUM(CASE
                WHEN SalesYear = 2024
                THEN TotalSales
                ELSE 0
            END) AS Sales_2024,

        SUM(CASE
                WHEN SalesYear = 2025
                THEN TotalSales
                ELSE 0
            END) AS Sales_2025
     from MonthlySales
      group by
            SalesMonth,
            productid,
             ProductName
),
productMonthlysalesComparison AS
(
    SELECT
        ProductID,
        ProductName,
        SalesMonth,
        Sales_2024,
        Sales_2025,

        CASE
            WHEN Sales_2024 > 0 AND Sales_2025 > 0
            THEN Sales_2025 - Sales_2024
            ELSE NULL
        END AS Sales_Difference,

        CASE
            WHEN Sales_2024 > 0 AND Sales_2025 > 0
            THEN CAST(
                100.0 * (Sales_2025 - Sales_2024)
                / NULLIF(Sales_2024, 0)
                AS DECIMAL(10,2)
            )
            ELSE NULL
        END AS YoYGrowthPct

    FROM MonthComparison
),

FinalComparison AS
(
    SELECT *,
        CASE
            WHEN Sales_2024 = 0 AND Sales_2025 = 0
                THEN 'No Sales in Either Year'

            WHEN Sales_2024 = 0
                THEN 'No Previous Year Data'

            WHEN Sales_2025 = 0
                THEN 'No Current Year Data'

            WHEN YoYGrowthPct > 0
                THEN 'Increased by ' +
                     CAST(YoYGrowthPct AS VARCHAR(20)) + '%'

            WHEN YoYGrowthPct < 0
                THEN 'Decreased by ' +
                     CAST(ABS(YoYGrowthPct) AS VARCHAR(20)) + '%'

            ELSE 'No Change'
        END AS ComparisonStatus
    FROM productMonthlysalesComparison
)

SELECT *
FROM FinalComparison;


SELECT TOP 10
    ProductID,
    ProductName,
    SUM(Sales_2024) AS Sales_2024,
    SUM(Sales_2025) AS Sales_2025,
    SUM(Sales_2025) - SUM(Sales_2024)
        AS Sales_Difference,
    CAST(
        100.0 * (SUM(Sales_2025) - SUM(Sales_2024))
        / NULLIF(SUM(Sales_2024), 0)
        AS DECIMAL(10,2)
    ) AS YoYGrowthPct
FROM dbo.vw_monthlyproductsaleanalysis

GROUP BY ProductID, ProductName
HAVING SUM(Sales_2024) > 0
   AND SUM(Sales_2025) < SUM(Sales_2024)
ORDER BY Sales_Difference ASC;





SELECT
    ProductID,
    ProductName,
    SalesMonth,
    SUM(Sales_2024) AS Sales_2024,
    SUM(Sales_2025) AS Sales_2025
FROM dbo.vw_monthlyproductsaleanalysis
GROUP BY SalesMonth, ProductID, ProductName
HAVING SUM(Sales_2024) > 0
   AND SUM(Sales_2025) = 0
ORDER BY SUM(Sales_2024) DESC;


