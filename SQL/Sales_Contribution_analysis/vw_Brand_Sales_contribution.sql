Use sales;

drop view if exists dbo.vw_Brand_Sales_contribution

CREATE OR ALTER VIEW dbo.vw_Brand_Sales_contribution as

SELECT
    p.Brand,

    SUM(f.SalesAmount) AS BrandSales,

    SUM(SUM(f.SalesAmount)) OVER() AS TotalSales,

    CAST(
        SUM(f.SalesAmount) * 100.0
        / SUM(SUM(f.SalesAmount)) OVER()
        AS DECIMAL(10,2)
    ) AS SalesContributionPercentage

FROM FactSales f

INNER JOIN DimProducts p
    ON f.Productid = p.Productid

GROUP BY
    p.Brand

SELECT *
FROM dbo.vw_Brand_Sales_contribution 
ORDER BY SalesContributionPercentage DESC;