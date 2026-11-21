# Retail Sales Analysis using SQL Server and Microsoft Excel

## 1. Project Overview

This project focuses on analysing retail sales data using Microsoft Excel and Microsoft SQL Server to evaluate business performance, identify sales trends and generate actionable business insights.

The project follows an end-to-end data analysis workflow, starting with data cleaning in Excel, followed by database management and business analysis using SQL Server, and finally developing analytical reports and visualisations in Excel.

The main objective is to transform raw sales data into meaningful information that supports data-driven business decisions.

## 2. Project Objectives

- Analyse overall sales performance and revenue trends.
- Evaluate product and category performance.
- Understand customer purchasing behaviour and retention.
- Identify brand sales growth and decline.
- Analyse inventory and stock availability.
- Compare sales performance across different time periods.
- Provide business insights and recommendations based on analytical findings.

## 3. Tools and Technologies

| Tool | Purpose |
|---|---|
| Microsoft Excel | Initial data cleaning and reporting |
| Microsoft SQL Server | Database management and data analysis |
| SQL Server Management Studio (SSMS) | Writing and executing SQL queries |
| Power Query | Connecting Excel to SQL Server and retrieving analytical data |

## 4. Dataset Description

The project uses three datasets:

1. Sales Dataset – Contains sales transaction information.
2. Products Dataset – Contains product details and inventory information.
3. Customers Dataset – Contains customer information.

The datasets were reviewed and cleaned before being imported into SQL Server.

## 5. Data Cleaning – Microsoft Excel

Initial data cleaning and preparation were performed using Microsoft Excel.

Key activities included:

- Identifying missing and invalid values.
- Checking duplicate records.
- Correcting inconsistent data formats.
- Reviewing data quality issues.
- Preparing datasets for SQL Server import.

The cleaned datasets were subsequently imported into SQL Server for further analysis.

## 6. Database Management – SQL Server

Microsoft SQL Server was used to organise the cleaned datasets into structured database tables.

Key activities included:

- Creating the database and tables.
- Importing cleaned datasets.
- Establishing relationships between tables.
- Defining primary and foreign keys.
- Creating analytical SQL views.

## 7. SQL Concepts Used

The following SQL concepts and techniques were applied:

- SELECT, WHERE and ORDER BY
- GROUP BY and aggregate functions
- INNER JOIN and LEFT JOIN
- CASE statements
- Common Table Expressions (CTEs)
- Subqueries
- Window functions
- RANK and ROW_NUMBER
- LAG and NTILE
- Date functions
- NULLIF and conditional calculations
- Views

These techniques were used to clean, transform, aggregate and analyse sales data.

## 8. Business Analysis

The project covers the following analytical areas:

### 8.1 Overall Sales Analysis
- Total sales revenue.
- Annual sales performance.
- Sales contribution.
- Overall business performance.

### 8.2 Monthly Sales Trend Analysis
- Monthly revenue trends.
- Month-on-month sales growth.
- Monthly sales increases and declines.
- Identification of significant sales fluctuations.

### 8.3 Product Performance Analysis
- Product-level sales performance.
- Best-performing and declining products.
- Product sales contribution.
- Product performance comparisons.

### 8.4 Category Performance Analysis
- Sales performance by product category.
- Category-level revenue contribution.
- Growing and declining categories.
- Comparison of category performance across periods.

### 8.5 Customer Analysis and Retention
- Customer purchasing behaviour.
- Customer sales contribution.
- Customer segmentation.
- High-value, medium-value and low-value customers.
- H1 2024 versus H1 2025 sales comparison.

### 8.6 Brand Sales Gap Analysis
- Brand-level sales comparison.
- H1 2024 versus H1 2025 performance.
- Sales gap identification.
- Brand growth and decline classification.

### 8.7 Inventory Analysis
- Inventory status distribution.
- Stock availability.
- Inventory and sales performance.
- Identification of inventory-related opportunities.

### 8.8 Year-on-Year Sales Analysis
- Annual sales comparison.
- Year-on-year revenue growth.
- Sales performance changes.
- Identification of significant annual trends.

## 9. Excel Reporting and Visualisation

Microsoft Excel was used to develop analytical reports and present business findings.

The reporting process included:

- Connecting Excel to SQL Server using Power Query.
- Retrieving data from SQL analytical views.
- Developing KPI summaries.
- Creating sales performance tables.
- Building charts and visualisations.
- Presenting business insights and recommendations.

## 10. Key Business Findings

The following findings were identified from the sales analysis:

### Overall Sales Performance

| Year | Total Sales |
|---|---:|
| 2023 | £998,471 |
| 2024 | £1,077,765 |
| 2025 (January–June) | £625,166 |

- Total recorded sales: approximately £2.70 million.
- Sales increased by 7.94% in 2024 compared with 2023.
- 2025 data covers only the first six months and should not be directly compared with full-year figures.

### Category Performance

- Health & Wellness recorded 355.99% growth in H1 2025 compared with H1 2024.
- Office Supplies recorded an 81.29% decline over the same period.

### Customer Analysis

- Customer segmentation identified high-value, medium-value and low-value customer groups.
- Customer sales performance was compared between H1 2024 and H1 2025.

### Brand Performance

- Brand-level sales comparisons identified growing and declining brands.
- Some brands recorded no sales in H1 2025 despite generating sales in H1 2024.

### Inventory Analysis

- Inventory was analysed across different stock availability statuses.
- Sales and inventory information was examined to identify potential stock management opportunities.

## 11. Business Insights and Recommendations

Based on the analysis, the following business recommendations are proposed.

### Overall Sales Performance
- Monitor monthly sales trends to identify significant fluctuations.
- Investigate periods of declining sales.
- Compare equivalent reporting periods for accurate performance evaluation.

### Product Performance
- Review consistently declining products.
- Focus on products with strong sales contributions.
- Evaluate pricing, availability and customer demand.

### Category Performance
- Investigate the significant decline in Office Supplies.
- Explore opportunities to maintain and expand Health & Wellness growth.
- Review category-level sales contributions to support business decisions.

### Customer Retention
- Develop targeted engagement strategies for high-value customers.
- Monitor repeat purchasing behaviour.
- Identify opportunities to improve customer retention.

### Brand Performance
- Investigate brands with no recorded sales in H1 2025.
- Review product availability and customer demand.
- Identify growing brands and opportunities to increase their sales contribution.

### Inventory Management
- Monitor stock availability regularly.
- Identify potential stock shortages and excess inventory.
- Align inventory planning with historical sales patterns and customer demand.

### Year-on-Year Performance
- Use like-for-like period comparisons.
- Investigate significant changes in sales performance.
- Monitor monthly growth and decline to identify emerging trends.

## 12. Project Workflow

The project followed these stages:

1. Review raw sales, product and customer datasets.
2. Perform initial data cleaning using Microsoft Excel.
3. Import cleaned datasets into SQL Server.
4. Create database tables and relationships.
5. Develop SQL queries and analytical views.
6. Perform business analysis using SQL Server.
7. Connect Excel to SQL Server using Power Query.
8. Develop KPI reports, tables and visualisations.
9. Identify business findings and recommendations.

## 13. Project Structure

```text
Retail-Sales-Analysis
│
├── 01_Data_Cleaning_Excel
│   ├── Sales_Cleaned.xlsx
│   ├── Products_Cleaned.xlsx
│   └── Customers_Cleaned.xlsx
│
├── 02_SQL_Server
│   ├── 01_Database_Setup
│   ├── 02_Data_Import
│   ├── 03_Overall_Sales
│   ├── 04_Monthly_Sales_Trend
│   ├── 05_Product_Analysis
│   ├── 06_Category_Analysis
│   ├── 07_Customer_Analysis
│   ├── 08_Brand_Analysis
│   ├── 09_Inventory_Analysis
│   └── 10_YoY_Analysis
│
├── 03_Excel_Reporting
│   ├── Sales_Analysis.xlsx
│   └── Screenshots
│
└── README.md
```

## 14. Conclusion

This project demonstrates the practical application of Microsoft Excel and SQL Server in an end-to-end retail sales analysis workflow.

By combining data cleaning, database management, SQL analysis and Excel reporting, the project transforms raw data into meaningful business insights.

It also demonstrates the ability to analyse business performance, identify trends, investigate potential issues and develop recommendations to support data-driven decision-making.

## 15. Skills Demonstrated

- Data Cleaning and Preparation
- Microsoft Excel
- SQL Server
- SQL Query Development
- Data Transformation
- Data Analysis
- KPI Reporting
- Data Visualisation
- Business Insights
- Analytical Problem-Solving
