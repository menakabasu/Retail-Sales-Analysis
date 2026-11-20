USE Sales;

CREATE OR ALTER VIEW dbo.vw_NewReturningCustomers
AS

WITH CustomerYearlySales AS
(
    -- Step 1: Calculate each customer's sales for each year
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

CustomerFirstPurchase AS
(
    -- Step 2: Find the first recorded purchase year
    -- for each customer in the available dataset

    SELECT
        CustomerID,

        MIN(OrderYear) AS FirstPurchaseYear

    FROM CustomerYearlySales

    GROUP BY
        CustomerID
)

-- Step 3: Combine yearly customer sales
-- with the customer's first purchase year

SELECT

    cys.OrderYear,

    cys.CustomerID,

    cys.CustomerName,

    cys.Country,

    cys.City,

    cfp.FirstPurchaseYear,

    -- New or Returning customer
    CASE
        WHEN cys.OrderYear = cfp.FirstPurchaseYear
            THEN 'New'

        ELSE 'Returning'
    END AS CustomerType,

    -- Sales
    cys.TotalSales,

    -- Quantity
    cys.TotalQuantity,

    -- Orders
    cys.TotalOrders,

    -- Average Order Value
    CAST(
        cys.TotalSales / NULLIF(cys.TotalOrders, 0)
        AS DECIMAL(18,2)
    ) AS AOV

FROM CustomerYearlySales cys

INNER JOIN CustomerFirstPurchase cfp
    ON cys.CustomerID = cfp.CustomerID;

    SELECT
    OrderYear,
    CustomerType,
    COUNT(DISTINCT CustomerID) AS CustomerCount
FROM dbo.vw_NewReturningCustomers
GROUP BY
    OrderYear,
    CustomerType
ORDER BY
    OrderYear,
    CustomerType;