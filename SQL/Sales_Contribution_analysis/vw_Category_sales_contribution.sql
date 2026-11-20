Use sales;

drop view if exists dbo.vw_Category_Sales_contribution

CREATE OR ALTER VIEW dbo.vw_Category_Sales_contribution as

SELECT
    p.Category,

    SUM(f.SalesAmount) AS CategorySales,

    SUM(SUM(f.SalesAmount)) OVER() AS TotalSales,

    CAST(
        SUM(f.SalesAmount) * 100.0
        / SUM(SUM(f.SalesAmount)) OVER()
        AS DECIMAL(10,2)
    ) AS SalesContributionPercentage

FROM FactSales f

INNER JOIN DimProducts p
    ON f.Productid= p.Productid

GROUP BY
    p.Category

select * from dbo.vw_Category_Sales_contribution
order by SalesContributionPercentage desc;
