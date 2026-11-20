USE Sales;
GO


/* ============================================================
   1. CUSTOMER VALUE SEGMENTATION VIEW
   ============================================================ */


DROP VIEW IF EXISTS dbo.vw_CustomerValueSegmentation;
GO

USE Sales;
GO



CREATE OR ALTER VIEW dbo.vw_CustomerValueSegmentation
AS

WITH CustomerSales AS
(
    SELECT
        c.CustomerID,

        CONCAT(c.FirstName, ' ', c.LastName) AS CustomerName,

        SUM(fs.SalesAmount) AS TotalSales

    FROM dbo.FactSales fs

    INNER JOIN dbo.DimCustomers c
        ON fs.CustomerID = c.CustomerID

    GROUP BY
        c.CustomerID,
        c.FirstName,
        c.LastName
),

CustomerSegments AS
(
    SELECT
        CustomerID,
        CustomerName,
        TotalSales,

        NTILE(4) OVER
        (
            ORDER BY TotalSales DESC
        ) AS SalesQuartile

    FROM CustomerSales
),

SegmentedCustomers AS
(
    SELECT
        CustomerID,
        CustomerName,
        TotalSales,

        CASE
            WHEN SalesQuartile = 1
                THEN 'High Value'

            WHEN SalesQuartile IN (2,3)
                THEN 'Medium Value'

            WHEN SalesQuartile = 4
                THEN 'Low Value'
        END AS CustomerSegment

    FROM CustomerSegments
)

SELECT
    CustomerSegment,

    /* Number of customers */
    COUNT(*) AS Customers,

    /* % of customers */
    CAST(
        COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER ()
        AS DECIMAL(10,2)
    ) AS CustomerPercentage,

    /* Total sales */
    SUM(TotalSales) AS TotalSales,

    /* % of sales */
    CAST(
        SUM(TotalSales) * 100.0
        / SUM(SUM(TotalSales)) OVER ()
        AS DECIMAL(10,2)
    ) AS SalesPercentage,

    /* Average sales per customer */
    CAST(
        SUM(TotalSales) * 1.0
        / COUNT(*)
        AS DECIMAL(18,2)
    ) AS AvgSalesPerCustomer

FROM SegmentedCustomers

GROUP BY
    CustomerSegment;
GO

select * from dbo.vw_CustomerValueSegmentation
/* ------------------------------------------------------------
   Final customer segmentation output
   ------------------------------------------------------------ */
SELECT CustomerSegment, Customers , TotalSales
FROM dbo.vw_CustomerValueSegmentation





/* ============================================================
   2. CUSTOMER COUNT BY SEGMENT
   Question:
   How many customers are in each value segment?
   ============================================================ */

SELECT
    CustomerSegment,
    COUNT(*) AS TotalCustomers

FROM dbo.vw_CustomerValueSegmentation

GROUP BY CustomerSegment

ORDER BY TotalCustomers DESC;



/* ============================================================
   3. CUSTOMER PERCENTAGE BY SEGMENT
   Question:
   What percentage of customers belong to each segment?
   ============================================================ */

SELECT
    CustomerSegment,
    COUNT(*) AS TotalCustomers,
    MAX(CustomerPercentage) AS CustomerPercentage

FROM dbo.vw_CustomerValueSegmentation

GROUP BY CustomerSegment

ORDER BY CustomerPercentage DESC;



/* ============================================================
   4. SALES CONTRIBUTION BY CUSTOMER SEGMENT
   Question:
   How much total sales does each customer segment generate?
   ============================================================ */

WITH SegmentSales AS
(
    SELECT
        CustomerSegment,
        SUM(TotalSales) AS TotalSales

    FROM dbo.vw_CustomerValueSegmentation

    GROUP BY CustomerSegment
)

SELECT
    CustomerSegment,
    TotalSales,

    CAST
    (
        TotalSales * 100.0
        /
        NULLIF(SUM(TotalSales) OVER (), 0)
        AS DECIMAL(10,2)
    ) AS SalesContributionPercentage

FROM SegmentSales

ORDER BY TotalSales DESC;



/* ============================================================
   5. CUSTOMER BEHAVIOUR BY SEGMENT
   Question:
   How do High, Medium and Low Value customers behave?
   ============================================================ */

SELECT
    CustomerSegment,
    count(*) as No_of_Customers,
    AVG(TotalOrders) AS AverageOrdersPerCustomer,

    SUM(TotalOrders) AS TotalOrders,

    SUM(TotalQuantity) AS TotalQuantity,

    AVG(AverageOrderValue) AS AverageOrderValue

FROM dbo.vw_CustomerValueSegmentation

GROUP BY CustomerSegment

ORDER BY AverageOrdersPerCustomer DESC;



/* ============================================================
   6. CUSTOMER PERFORMANCE WITHIN EACH SEGMENT
   Question:
   Which customers are the highest-value customers in each segment?
   ============================================================ */

SELECT
    CustomerSegment,
    CustomerName,
    TotalSales,
    TotalOrders,
    AverageOrderValue,
    SalesRank

FROM dbo.vw_CustomerValueSegmentation

ORDER BY
    CustomerSegment,
    TotalSales DESC;



/* ============================================================
   7. TOP 10 CUSTOMERS BY SALES
   Question:
   Who are the top 10 customers?
   ============================================================ */

SELECT
    CustomerName,
    TotalSales,
    TotalOrders,
    AverageOrderValue,
    SalesRank

FROM dbo.vw_CustomerValueSegmentation

WHERE SalesRank <= 10

ORDER BY SalesRank;



/* ============================================================
   8. HIGH-VALUE CUSTOMER SALES CONTRIBUTION
   Question:
   How much of total sales comes from High Value customers?
   ============================================================ */

SELECT
    SUM(TotalSales) AS HighValueSales,

    CAST
    (
        SUM(TotalSales) * 100.0
        /
        (
            SELECT SUM(TotalSales)
            FROM dbo.vw_CustomerValueSegmentation
        )
        AS DECIMAL(10,2)
    ) AS HighValueSalesPercentage

FROM dbo.vw_CustomerValueSegmentation

WHERE CustomerSegment = 'High Value';