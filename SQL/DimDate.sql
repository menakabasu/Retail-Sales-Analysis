use Sales
DROP TABLE IF EXISTS dbo.DimDate;
CREATE TABLE dbo.DimDate
(
    DateKey INT NOT NULL,
    FullDate DATE NOT NULL,
    Year INT NOT NULL,
    Quarter INT NOT NULL,
    QuarterName VARCHAR(2) NOT NULL,
    Month INT NOT NULL,
    MonthName VARCHAR(20) NOT NULL,
    MonthYear VARCHAR(20) NOT NULL,
    WeekOfYear INT NOT NULL,
    Day INT NOT NULL,
    DayName VARCHAR(20) NOT NULL,
    DayOfWeek INT NOT NULL,

    CONSTRAINT PK_DimDate
        PRIMARY KEY (FullDate)
);

DECLARE @StartDate DATE;
DECLARE @EndDate DATE;

SELECT
    @StartDate = MIN(OrderDate),
    @EndDate = MAX(OrderDate)
FROM dbo.FactSales;

;WITH DateSequence AS
(
    SELECT @StartDate AS FullDate

    UNION ALL

    SELECT DATEADD(DAY, 1, FullDate)
    FROM DateSequence
    WHERE FullDate < @EndDate
)
INSERT INTO dbo.DimDate
(
    DateKey,
    FullDate,
    Year,
    Quarter,
    QuarterName,
    Month,
    MonthName,
    MonthYear,
    WeekOfYear,
    Day,
    DayName,
    DayOfWeek
)
SELECT
    CONVERT(INT, CONVERT(VARCHAR(8), FullDate, 112)) AS DateKey,

    FullDate,

    YEAR(FullDate) AS Year,

    DATEPART(QUARTER, FullDate) AS Quarter,

    'Q' + CAST(DATEPART(QUARTER, FullDate) AS VARCHAR(1)) AS QuarterName,

    MONTH(FullDate) AS Month,

    DATENAME(MONTH, FullDate) AS MonthName,

    DATENAME(MONTH, FullDate) + ' ' +
        CAST(YEAR(FullDate) AS VARCHAR(4)) AS MonthYear,

    DATEPART(WEEK, FullDate) AS WeekOfYear,

    DAY(FullDate) AS Day,

    DATENAME(WEEKDAY, FullDate) AS DayName,

    DATEPART(WEEKDAY, FullDate) AS DayOfWeek

FROM DateSequence

OPTION (MAXRECURSION 0);

ALTER TABLE dbo.FactSales
ADD CONSTRAINT FK_FactSales_DimDate
FOREIGN KEY (OrderDate)
REFERENCES dbo.DimDate(FullDate);

SELECT
    FullDate,
    COUNT(*) AS DateCount
FROM dbo.DimDate
GROUP BY FullDate
HAVING COUNT(*) > 1;