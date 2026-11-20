Use sales;
drop view if exists dbo.vw_CustomerSalesContribution

CREATE OR ALTER VIEW dbo.vw_CustomerSalesContribution
AS
SELECT
    c.CustomerID,
    CONCAT(c.FirstName, ' ', c.LastName) AS CustomerName,

    SUM(f.SalesAmount) AS CustomerSales,

    SUM(SUM(f.SalesAmount)) OVER () AS TotalSales,

    CAST(
        SUM(f.SalesAmount) * 100.0
        / SUM(SUM(f.SalesAmount)) OVER ()
        AS DECIMAL(10,2)
    ) AS SalesContributionPercentage

FROM dbo.FactSales AS f

INNER JOIN dbo.DimCustomers AS c
    ON f.CustomerID = c.CustomerID

GROUP BY
    c.CustomerID,
    CONCAT(c.FirstName, ' ', c.LastName);


      SELECT *
FROM vw_CustomerSalesContribution



SELECT TOP 10
    CustomerName,
    CustomerSales,
    SalesContributionPercentage
FROM vw_CustomerSalesContribution
ORDER BY CustomerSales DESC;