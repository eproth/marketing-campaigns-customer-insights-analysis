USE marketing_campaign;
-- Inspect the data
/*
SELECT *
FROM `marketing_campaign.csv` `marketing_campaign.csv` mcc 
LIMIT 100;
*/

/*
 * ==== CLEANING THE DATA =====
 */

/* Check duplicates
SELECT ID, COUNT(*) AS duplicate_count
FROM `marketing_campaign.csv` mcc
GROUP BY ID, Year_Birth, Education, Marital_Status, Income
HAVING COUNT(*) > 1;
*/

/*
-- Find the missing Income
SELECT *
FROM `marketing_campaign.csv` mcc
WHERE Income IS NULL;
*/

/*
-- Calculate the percentage missing
SELECT
    COUNT(*) AS missing_income,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM `marketing_campaign.csv` mcc), 2) AS missing_percentage
FROM `marketing_campaign.csv` mcc
WHERE Income IS NULL;
*/

/*
-- Remove the rows since it's less than 5%
DELETE FROM `marketing_campaign.csv` mcc
WHERE Income IS NULL;
*/

/* View the Education column
SELECT Education, COUNT(*) AS customer_count
FROM `marketing_campaign.csv` mcc 
GROUP BY Education
ORDER BY customer_count DESC;
*/

/*
-- Update the Education column for easier interpret
UPDATE `marketing_campaign.csv` mcc
SET Education = CASE
    WHEN Education IN ('Basic', '2n Cycle') THEN 'Pre-Bachelor''s'
    WHEN Education = 'Graduation' THEN 'Bachelor''s'
    WHEN Education = 'Master' THEN 'Master''s'
    WHEN Education = 'PhD' THEN 'PhD'
END;

-- View the result
SELECT Education, COUNT(*) AS customer_count
FROM `marketing_campaign.csv` mcc
GROUP BY Education
ORDER BY customer_count DESC;
*/

/*
-- Create new columns
ALTER TABLE `marketing_campaign.csv` 
ADD COLUMN Age INT,
ADD COLUMN Total_Spending DECIMAL(10,2),
ADD COLUMN Total_Purchases INT,
ADD COLUMN Total_Children INT,
ADD COLUMN Campaigns_Accepted INT,
ADD COLUMN Age_Group VARCHAR(30);



UPDATE `marketing_campaign.csv`
SET 
    Age = 2026 - Year_Birth,
    
    Total_Spending = 
        MntWines +
        MntFruits +
        MntMeatProducts +
        MntFishProducts +
        MntSweetProducts +
        MntGoldProds,
    
    Total_Purchases =
        NumWebPurchases +
        NumCatalogPurchases +
        NumStorePurchases,
    
    Total_Children =
        Kidhome + Teenhome,
    
    Campaigns_Accepted =
        AcceptedCmp1 +
        AcceptedCmp2 +
        AcceptedCmp3 +
        AcceptedCmp4 +
        AcceptedCmp5;
    
-- Check the values
SELECT 
    ID,
    Age,
    Total_Spending,
    Total_Purchases,
    Total_Children,
    Campaigns_Accepted
FROM `marketing_campaign.csv` mcc 
LIMIT 10;
*/

/*
 * ==== EXPLORATORY DATA ANALYSIS =====
 */

/*
-- Customer distribution by Education
SELECT Education, COUNT(*) AS Total_Customer
FROM `marketing_campaign.csv` mcc 
GROUP BY Education;

-- Average Spending by Education, ranked, with subtotal/grand total
SELECT Education, ROUND(AVG(Total_Spending), 2) AS Avg_Spending
FROM `marketing_campaign.csv` mcc 
GROUP BY Education WITH ROLLUP;
*/

/*
-- Product Performance
SELECT 
	SUM(mcc.MntFishProducts) AS Fish,
	SUM(mcc.MntFruits) AS Fruit,
	SUM(mcc.MntGoldProds) AS Gold,
	SUM(mcc.MntMeatProducts) AS Meat,
	SUM(mcc.MntSweetProducts) AS Sweet,
	SUM(mcc.MntWines) AS Wine
FROM `marketing_campaign.csv` mcc ;

-- Purchase Channel
SELECT 
	SUM(mcc.NumWebPurchases) AS Web_Purchase,
	SUM(mcc.NumStorePurchases) AS Store_Purchase,
	SUM(mcc.NumCatalogPurchases) AS Catalog_Purchase 
FROM `marketing_campaign.csv` mcc ;
*/

/*
-- Response Rate
SELECT AVG(mcc.Response) * 100 AS Response_Rate
FROM `marketing_campaign.csv` mcc ;

-- Campaign Acceptance
SELECT
	SUM(mcc.AcceptedCmp1) AS Campaign1,
	SUM(mcc.AcceptedCmp2) AS Campaign2,
	SUM(mcc.AcceptedCmp3) AS Campaign3,
	SUM(mcc.AcceptedCmp4) AS Campaign4,
	SUM(mcc.AcceptedCmp5) AS Campaign5
FROM `marketing_campaign.csv` mcc ;
*/

/*
-- Total Revenue
SELECT SUM(mcc.Z_Revenue) AS Revenue
FROM `marketing_campaign.csv` mcc ;

-- Average Customer Value
SELECT ROUND(AVG(mcc.Total_Spending), 2) AS Averge_Customer_Value
FROM `marketing_campaign.csv` mcc ;

-- Revenue by Education
SELECT mcc.Education, SUM(mcc.Total_Spending) AS Total_Revenue
FROM `marketing_campaign.csv` mcc 
GROUP BY Education;

-- Which customers actually drive the revenue in each education group
-- (spending above their own group's average, using a correlated subquery)
SELECT mcc.ID, mcc.Education, mcc.Total_Spending
FROM `marketing_campaign.csv` mcc
WHERE mcc.Total_Spending > (
    SELECT AVG(m2.Total_Spending)
    FROM `marketing_campaign.csv` m2
    WHERE m2.Education = mcc.Education
);

-- Same idea, but summarized: high-value customer count and revenue per education
-- group, built with two chained CTEs so the "above average" logic is reusable
WITH Education_Summary AS (
    SELECT 
        Education, 
        ROUND(AVG(Total_Spending), 2) AS Avg_Spending
    FROM `marketing_campaign.csv`
    GROUP BY Education
),
High_Value_Customers AS (
    SELECT 
        mcc.ID, 
        mcc.Education, 
        mcc.Total_Spending
    FROM `marketing_campaign.csv` mcc
    JOIN Education_Summary es 
        ON mcc.Education = es.Education
    WHERE mcc.Total_Spending > es.Avg_Spending
)
SELECT 
    Education, 
    COUNT(*) AS High_Value_Count, 
    SUM(Total_Spending) AS High_Value_Revenue
FROM High_Value_Customers
GROUP BY Education
ORDER BY High_Value_Revenue DESC;

-- Revenue from Campaign Responders
SELECT Response,
	COUNT(*) AS Customers,
	AVG(mcc.Total_Spending) AS Average_Spending,
	SUM(mcc.Total_Spending) AS Revenue
FROM `marketing_campaign.csv` mcc 
GROUP BY mcc.Response;

-- Every customer's spending against the overall average, to spot outliers at a glance
SELECT 
    mcc.ID, 
    mcc.Total_Spending,
    (SELECT ROUND(AVG(Total_Spending), 2) FROM `marketing_campaign.csv`) AS Overall_Avg_Spending
FROM `marketing_campaign.csv` mcc;

-- Segment customers into spending quartiles for targeting (top 25% = premium tier)
SELECT 
    ID, 
    Total_Spending,
    NTILE(4) OVER (ORDER BY Total_Spending) AS Spending_Quartile
FROM `marketing_campaign.csv`;

-- Rank customers by spending within their own education group
SELECT 
    ID, 
    Education, 
    Total_Spending,
    RANK() OVER (PARTITION BY Education ORDER BY Total_Spending DESC) AS Spending_Rank
FROM `marketing_campaign.csv`;
*/

/*
-- Customer Growth Over Time
SELECT
YEAR(Dt_Customer) AS Year,
COUNT(ID) AS New_Customers
FROM `marketing_campaign.csv` mcc 
GROUP BY YEAR(Dt_Customer)
ORDER BY Year;

-- Revenue Growth Over Time, plus a running cumulative total
SELECT
    Dt_Customer,
    Total_Spending,
    SUM(Total_Spending) OVER (ORDER BY Dt_Customer) AS Running_Revenue
FROM `marketing_campaign.csv` mcc
ORDER BY Dt_Customer;

-- Month-over-month comparison: how each cohort's revenue compares to the one before it
SELECT
    YEAR(Dt_Customer) AS Year,
    SUM(Total_Spending) AS Revenue,
    LAG(SUM(Total_Spending)) OVER (ORDER BY YEAR(Dt_Customer)) AS Prev_Year_Revenue
FROM `marketing_campaign.csv` mcc
GROUP BY YEAR(Dt_Customer)
ORDER BY Year;
*/