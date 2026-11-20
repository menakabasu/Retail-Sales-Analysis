Use sales;
drop view if exists dbo.vw_CustomerPerformance_copy

CREATE OR ALTER VIEW dbo.vw_CustomerAnalysis
AS

WITH CustomerYearlySales AS
(
    SELECT
        YEAR(fs.OrderDate) AS OrderYear,
        c.CustomerID,
        CONCAT(c.FirstName, ' ', c.LastName) AS CustomerName,
        c.Country,
        c.City,

        SUM(fs.SalesAmount) AS TotalSales,
        SUM(fs.Quantity) AS TotalQuantity,
        COUNT(DISTINCT fs.OrderID) AS TotalOrders

    FROM dbo.FactSales fs

    INNER JOIN dbo.DimCustomers c
        ON fs.CustomerID = c.CustomerID

    GROUP BY
        YEAR(fs.OrderDate),
        c.CustomerID,
        c.FirstName,
        c.LastName,
        c.Country,
        c.City
),

CustomerYearlyPerformance AS
(
    SELECT
        OrderYear,
        CustomerID,
        CustomerName,
        Country,
        City,
        TotalSales,
        TotalQuantity,
        TotalOrders,

        -- Average Order Value
        CAST(
            TotalSales / NULLIF(TotalOrders, 0)
            AS DECIMAL(18,2)
        ) AS AOV,

        -- Sales Rank within each year
        RANK() OVER
        (
            PARTITION BY OrderYear
            ORDER BY TotalSales DESC
        ) AS SalesRank,

        -- Previous year's sales
        LAG(TotalSales) OVER
        (
            PARTITION BY CustomerID
            ORDER BY OrderYear
        ) AS PreviousYearSales

    FROM CustomerYearlySales
),

CustomerPerformance AS
(
    SELECT
        *,

        -- YoY Sales Change
        TotalSales - PreviousYearSales AS SalesChange,

        -- YoY Growth %
        CAST(
            (TotalSales - PreviousYearSales) * 100.0
            / NULLIF(PreviousYearSales, 0)
            AS DECIMAL(10,2)
        ) AS YoYGrowthPct

    FROM CustomerYearlyPerformance
),

CustomerContribution AS
(
    SELECT
        *,

        -- Customer contribution to total sales for that year
        CAST(
            TotalSales * 100.0
            / NULLIF(
                SUM(TotalSales) OVER
                (
                    PARTITION BY OrderYear
                ), 0
            )
            AS DECIMAL(10,2)
        ) AS SalesContributionPct,

        -- Cumulative sales %
        CAST(
            SUM(TotalSales) OVER
            (
                PARTITION BY OrderYear
                ORDER BY TotalSales DESC, CustomerID
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) * 100.0
            / NULLIF(
                SUM(TotalSales) OVER
                (
                    PARTITION BY OrderYear
                ), 0
            )
            AS DECIMAL(10,2)
        ) AS CumulativeSalesPct

    FROM CustomerPerformance
),

CustomerPareto AS
(
    SELECT
        *,

        -- Number of customers in that year
        COUNT(*) OVER
        (
            PARTITION BY OrderYear
        ) AS TotalCustomers,

        -- Customer percentage of total customer base
        CAST(
            100.0 / NULLIF(
                COUNT(*) OVER
                (
                    PARTITION BY OrderYear
                ), 0
            )
            AS DECIMAL(10,2)
        ) AS CustomerBasePct

    FROM CustomerContribution
)

SELECT

    --------------------------------------------------
    -- CUSTOMER INFORMATION
    --------------------------------------------------

    OrderYear,
    CustomerID,
    CustomerName,
    Country,
    City,

    --------------------------------------------------
    -- SALES PERFORMANCE
    --------------------------------------------------

    TotalSales,
    TotalQuantity,
    TotalOrders,
    AOV,

    --------------------------------------------------
    -- RANKING
    --------------------------------------------------

    SalesRank,

    --------------------------------------------------
    -- CONTRIBUTION
    --------------------------------------------------

    SalesContributionPct,

    --------------------------------------------------
    -- PARETO
    --------------------------------------------------

    CumulativeSalesPct,

    CASE
        WHEN CumulativeSalesPct <= 80
            THEN 'Top 80% Sales Customers'
        ELSE 'Remaining Customers'
    END AS ParetoSegment,

    TotalCustomers,

    CustomerBasePct,

    --------------------------------------------------
    -- YEAR-OVER-YEAR PERFORMANCE
    --------------------------------------------------

    PreviousYearSales,
    SalesChange,
    YoYGrowthPct,

    --------------------------------------------------
    -- PERFORMANCE STATUS
    --------------------------------------------------

    CASE

        -- No previous year
        WHEN PreviousYearSales IS NULL
             OR PreviousYearSales = 0
        THEN 'No Previous Year Data'

        -- Current sales missing/zero
        WHEN TotalSales IS NULL
             OR TotalSales = 0
        THEN 'No Current Year Data'

        -- Both current and previous are zero
        WHEN TotalSales = 0
             AND PreviousYearSales = 0
        THEN 'No Sales'

        -- Growth
        WHEN YoYGrowthPct > 10
        THEN 'Improving'

        -- Decline
        WHEN YoYGrowthPct < -10
        THEN 'Declining'

        -- Between -10% and +10%
        ELSE 'No Significant Change'

    END AS PerformanceStatus

FROM CustomerPareto;

select * from dbo.vw_CustomerAnalysis