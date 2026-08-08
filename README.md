# Marketing and Product Performance with Customer Insights Analysis for a Business Understanding

## Overview

A marketing team has customer data (demographics, spending, campaign responses) but no clear read on who their best customers are, what drives revenue, or whether their past campaigns actually worked. This project turns raw customer data into answers to a few core business questions:

- Who are the highest-value customers, and what do they have in common?
- Which products and purchase channels drive the most revenue?
- How effective were the past marketing campaigns?
- How has customer revenue grown over time?

The full pipeline: raw CSV → SQL cleaning → SQL exploratory analysis → Tableau dashboard.

## Dataset Description
The Marketing Campaign dataset contains information about customer demographics, purchasing behavior, and responses to previous marketing campaigns.
- Customer-level marketing data including demographics (`Year_Birth`, `Education`, `Marital_Status`, `Income`)
- Household info (`Kidhome`, `Teenhome`)
- Spending by product category (`MntWines`, `MntFruits`, `MntMeatProducts`, `MntFishProducts`, `MntSweetProducts`, `MntGoldProds`)
- Purchase channel counts (`NumWebPurchases`, `NumStorePurchases`, `NumCatalogPurchases`)
- Campaign response flags (`AcceptedCmp1`–`5`, `Response`).

## Tools

- **SQL (MySQL)** — data cleaning, feature engineering, exploratory analysis
- **Tableau** — dashboard and visualization

## Data cleaning

- **Duplicate check.** Grouped on `ID` plus key demographic fields and filtered for groups with more than one row, to confirm no duplicate customer records existed.
- **Missing values.** `Income` had a small number of nulls. Since the missing percentage was less than 5% of the dataset, the rows were removed rather than imputed, to avoid introducing bias into spending analysis.
- **Standardizing categories.** `Education` originally had inconsistent, overlapping labels (`Basic`, `2n Cycle`, `Graduation`, `Master`, `PhD`). These were consolidated into a clearer four-tier scale (`Pre-Bachelor's`, `Bachelor's`, `Master's`, `PhD`) using a `CASE` statement, so later grouped analysis would read cleanly.
- **Feature engineering.** Added derived columns to support analysis instead of repeating the same calculations in every query:

| Column | Definition |
|---|---|
| `Age` | Current year minus `Year_Birth` |
| `Total_Spending` | Sum of all six product spending columns |
| `Total_Purchases` | Sum of web, store, and catalog purchase counts |
| `Total_Children` | `Kidhome` + `Teenhome` |
| `Campaigns_Accepted` | Sum of the five campaign acceptance flags |

```sql
UPDATE `marketing_campaign.csv`
SET 
    Age = 2026 - Year_Birth,
    Total_Spending = MntWines + MntFruits + MntMeatProducts 
                    + MntFishProducts + MntSweetProducts + MntGoldProds,
    Total_Purchases = NumWebPurchases + NumCatalogPurchases + NumStorePurchases,
    Total_Children = Kidhome + Teenhome,
    Campaigns_Accepted = AcceptedCmp1 + AcceptedCmp2 + AcceptedCmp3 
                        + AcceptedCmp4 + AcceptedCmp5;
```

## Exploratory analysis

### Customer segmentation

Baseline distribution and spend by `Education`, using `GROUP BY` with `HAVING` to filter out negligibly small segments, and `WITH ROLLUP` to get subtotal and grand-total rows alongside the group breakdown in a single query.

### Product and channel performance

Aggregated total spend across all six product categories and total purchase volume across the three channels (web, store, catalog), to see where revenue concentrates.

### Campaign performance

Measured overall `Response` rate and acceptance counts per individual campaign (`AcceptedCmp1`–`5`), to compare which campaigns actually landed versus which underperformed.

### Identifying high-value customers

Two approaches were used here, deliberately, to show both row-level and set-level thinking:

- **Correlated subquery** — flags individual customers spending above their *own education group's* average, not the dataset-wide average, which is a more meaningful bar than a single global threshold.

```sql
SELECT mcc.ID, mcc.Education, mcc.Total_Spending
FROM `marketing_campaign.csv` mcc
WHERE mcc.Total_Spending > (
    SELECT AVG(m2.Total_Spending)
    FROM `marketing_campaign.csv` m2
    WHERE m2.Education = mcc.Education
);
```

- **CTEs** — the same logic restructured as two chained `WITH` clauses (`Education_Summary` → `High_Value_Customers`), which is more readable and reusable than nesting the subquery repeatedly, and summarizes straight to a count/revenue rollup per group.

### Quartile segmentation

Used the `NTILE(4)` window function to split all customers into four equal-sized spending tiers, which is a cleaner way to identify the top-spending segment than picking an arbitrary cutoff.

```sql
SELECT ID, Total_Spending,
    NTILE(4) OVER (ORDER BY Total_Spending) AS Spending_Quartile
FROM `marketing_campaign.csv`;
```

### Revenue trends over time

Extended a standard year-over-year `GROUP BY` revenue query with `SUM() OVER (ORDER BY Dt_Customer)` for a running cumulative total, and `LAG()` to compare each period's revenue directly against the one before it, turning a flat yearly summary into an actual growth trend.

## Dashboard

Built in Tableau, includes customer segmentation, product/channel performance, quartile breakdown, and a cumulative revenue trend.

<strong>Link<strong>: *https://public.tableau.com/views/CustomerInsightsandRevenueDashboard/Dashboard1?:language=en-GB&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link*

## Key Findings

- **PhD customers have the highest average spending per person**, at $676.73, while **Bachelor's customers generate the highest total revenue**, at $693,802. This is mainly because the Bachelor's segment is much larger, with 1,116 customers compared to 481 PhD customers. Therefore, customer volume has a greater impact on total revenue than individual spending.

- **Wine is the dominant product category**, generating $676,083 in total spending. This is higher than the combined spending of the other five product categories, highlighting the company's strong dependence on Wine sales.

- **Store remains the most popular purchase channel**, with 12,855 purchases, followed by Web with 9,053 purchases and Catalog with 5,919 purchases.

- **Campaign 2 significantly underperformed compared to the other campaigns**, receiving only 30 acceptances, while Campaigns 1, 3, 4, and 5 received between 142 and 164 acceptances.

- **The overall campaign response rate was 15.03%**, meaning that only a relatively small proportion of customers responded to at least one campaign.

- **Campaign responders represent a small but highly valuable customer group.** The 333 customers who accepted at least one campaign generated $328,225 in revenue, with an average spend of $985.66. This is 82% higher than the $540.12 average spend among non-responders. This suggests that campaigns are particularly effective at engaging customers who already have high purchasing value rather than simply generating additional customer volume.

- **2013 was the peak acquisition year**, with 1,173 new customers generating $706,357 in cohort revenue. Although 2014 appears to show a decline, with 553 customers and $273,809 in revenue, this does not represent a true annual decline. The `Dt_Customer` field only covers approximately the first half of 2014. Therefore, when considering the partial-year data, 2014 was likely tracking closer to 2013's growth than the raw figures suggest.

## Recommendations

- **Segment marketing strategies based on customer value rather than segment size.** PhD customers have the highest average spending and may be more suitable for premium offers, while the larger Bachelor's segment could benefit from volume-driven retention and engagement campaigns.

- **Protect the strong performance of Wine while using it to support cross-selling.** Since Wine generates more revenue than all other product categories combined, it can serve as the main product for bundled promotions that encourage customers to purchase lower-performing categories such as Fruit and Sweets.

- **Continue prioritizing the Store channel.** Store purchases significantly outperform both Web and Catalog purchases combined. Therefore, digital investment should complement rather than replace the in-store experience.

- **Pause or redesign Campaign 2.** Its acceptance rate is approximately four to five times lower than that of the other campaigns. As a result, reallocating resources toward the stronger-performing campaigns, particularly Campaigns 3 to 5, could potentially improve marketing returns.

- **Prioritize retention among campaign responders before focusing heavily on new customer acquisition.** The 333 campaign responders already generate $328,225 in revenue and spend 82% more on average than non-responders. Therefore, strengthening engagement and retention within this group may be more cost-effective than focusing primarily on acquiring new customers.

## Conclusion

Overall, the business has a small but high-value PhD customer segment, while the larger Bachelor's segment generates the highest total revenue due to its size. The business also relies heavily on Wine sales, with the Store remaining its strongest purchase channel. In addition, campaign responders represent a relatively small but disproportionately valuable customer group.

Among the findings, **Campaign 2's underperformance and the high value of the 333 campaign responders are the most actionable insights**. Both findings are specific and measurable, making them useful for shaping future marketing decisions. Meanwhile, the apparent decline in 2014 revenue was found to be largely caused by partial-year data rather than an actual decline in performance. This highlights the importance of validating unusual changes in the data before interpreting them as long-term business trends.

## Limitations

- **2014 data is incomplete.** The dataset's `Dt_Customer` field only extends through roughly the first half of 2014, so 2014 acquisition and revenue figures aren't directly comparable to full-year 2012/2013 totals.
- **`Z_Revenue` is a placeholder field**, not real transaction revenue (flat $11 across all rows) — excluded from findings.
- **This analysis is descriptive, not predictive.** It identifies what happened in the data, not why it happened or what will happen next — a natural next step would be hypothesis testing or a predictive model (e.g., churn or response propensity).

## Repo structure
 
```
├── Customer Insights and Revenue Dashboard   # Tableau dashboard
├── Marketing Campaign and Customer Behavior Analysis   # Presentation file
├── campaign_customer_marketing.sql   # Cleaning + EDA queries
├── README.md                           # This file
```
