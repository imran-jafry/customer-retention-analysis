# Customer Retention & Repeat Purchase Analysis

> Analyzed customer purchasing behaviour in the Olist Brazilian E-Commerce Dataset using Google BigQuery, SQL, Python, and Power BI. Applied RFM segmentation and cohort analysis to examine repeat purchases, customer value, and retention patterns.

## Project Overview

This portfolio project explores customer purchasing behaviour in the Olist Brazilian E-Commerce Dataset, focusing on repeat purchases, customer segmentation, cohort retention, and historical revenue distribution.

**Business Problem:** How can an e-commerce business understand its customer base, identify valuable customer segments, and evaluate repeat-purchase behaviour?

**My Role:** Portfolio project — performed SQL-based data extraction and analysis, developed customer segmentation logic, conducted cohort analysis, explored purchasing patterns, and created a Power BI dashboard.

## Dataset

- **Source:** Olist Brazilian E-Commerce Dataset (Kaggle)
- **Period:** 2017–2018
- **Tables used:** 7 relational tables
- **Orders:** 99,441
- **Unique customers in source dataset:** 96,096
- **Analysis population:** 93,104 customers with delivered orders and valid payment records

The analysis uses `customer_unique_id` to identify customers across multiple orders rather than treating each order-level `customer_id` as a separate customer.

## Tools & Technologies

| Tool | Purpose |
|---|---|
| Google BigQuery | SQL analysis and data extraction |
| SQL | JOINs, CTEs, window functions and aggregations |
| Python | Exploratory data analysis |
| Pandas, Matplotlib, Seaborn | Data manipulation and visualization |
| Power BI | Interactive dashboard development |
| Kaggle | Dataset source |

## Business Questions

- What proportion of customers make repeat purchases?
- Which customer segments contribute most to historical revenue?
- How are customers distributed across RFM segments?
- How does retention vary across acquisition cohorts?
- How much time passes between a customer's first and subsequent purchases?
- Which product categories have higher same-category repeat-purchase rates?
- How does purchasing behaviour vary across review scores?

## Key Findings

### 1. Repeat Purchase Behaviour

- Customers analyzed: 93,104
- Repeat customers: 2,789
- Repeat-purchase rate: approximately 3.0%
- Single-purchase customers: approximately 97.0%

Repeat purchases were relatively uncommon during the observed dataset period.

**Limitation:** Customers acquired near the end of the observation period had less time to make another purchase. Therefore, this historical repeat-purchase rate should not be interpreted as a fully observed long-term retention rate.

### 2. RFM Customer Segmentation

Applied Recency, Frequency, and Monetary analysis to categorize customers into nine rule-based segments.

Segments included:

- Champions
- Loyal Customers
- Potential Loyalists
- At Risk Repeat
- High Value New
- New Customers
- Hibernating
- Lost
- Low Value Mid-Recency

The segmentation helps compare customer purchasing patterns and historical revenue contributions across groups.

**Key observation:** The High Value New segment contributed approximately 28.24% of historical revenue. This reflects the segment's spending-based definition and should not be interpreted as future revenue potential.

**Limitation:** Customer frequency was highly concentrated among one-time buyers. Frequency-based scoring therefore required adjusted segmentation logic. NTILE-based scoring can also split customers with tied values across score boundaries.

### 3. Cohort Retention Analysis

Grouped customers by their first purchase month to examine repeat-purchase behaviour over subsequent months.

- Analyzed 20 monthly cohorts.
- October 2017 recorded the highest Month 1 retention at approximately 0.72%.
- February 2017 recorded the lowest Month 1 retention at approximately 0.18%.
- Month 1 monthly retention remained below 1% across the observed cohorts.
- The simple average of the 19 observable Month 1 values was approximately 0.48%.

These are historical monthly-activity observations, not cumulative retention figures.

**Limitation:** The August 2018 cohort did not have a complete Month 1 observation window. Later cohorts also have shorter follow-up periods.

### 4. Time Between Purchases

Examined the time difference between customers' first and subsequent purchases.

- 1,412 repeat buyers had a recorded purchase gap of 0–30 days.
- This represents approximately 50.6% of the 2,789 repeat buyers.

**Limitation:** This calculation includes same-day purchases and is affected by the observation window. It describes the distribution among repeat buyers, not the probability that any customer will return within 30 days.

### 5. Product Category Analysis

Compared same-category repeat-purchase rates across product categories.

Examples from the analysis:

- Home Appliances: approximately 7.27% (50 of 688 customers)
- Fashion Bags: approximately 2.91%
- Bed Bath Table: approximately 2.72%
- Sports Leisure: approximately 2.32%
- Health Beauty: approximately 1.67%

These figures describe the observed category-level data. They do not establish why customers purchased again.

### 6. Review Score Analysis

Explored the relationship between customer review scores and purchasing behaviour.

The initial analysis had duplicate customer counting across review-score groups because customers could have multiple orders and reviews.

**This comparison requires a corrected customer-level analysis and is not presented as a validated finding in this project.**

## Python Exploratory Data Analysis

Used Python to explore customer segments, historical revenue distribution, cohort retention, and purchasing patterns.

Libraries:
- Pandas
- Matplotlib
- Seaborn

## Potential Business Applications

The analysis can help an e-commerce business:

- Identify customer groups with different purchasing patterns.
- Compare historical revenue contributions across customer segments.
- Monitor repeat-purchase behaviour over time.
- Evaluate retention patterns across acquisition cohorts.
- Identify product categories with comparatively higher same-category repeat-purchase rates.

These are potential applications of the analysis, not implemented campaigns or measured business outcomes.

## Data Challenges and Solutions

| Challenge | Approach |
|---|---|
| `customer_id` vs `customer_unique_id` | Used the customer-level identifier for repeat-purchase analysis. |
| Relational dataset structure | Joined relevant tables using their associated keys. |
| Product category names in Portuguese | Used the category translation table. |
| Sparse historical data | Focused the analysis on the 2017–2018 period. |
| Customer frequency imbalance | Adjusted segmentation logic to account for the high proportion of one-time buyers. |
| Missing or zero payment values | Applied payment-value filters where appropriate. |

## SQL Concepts Used

- Multi-table JOINs
- Common Table Expressions (CTEs)
- Window functions: NTILE, ROW_NUMBER, FIRST_VALUE and LEAD
- PARTITION BY
- DATE_TRUNC
- DATE_DIFF
- Self JOINs
- COUNTIF
- COALESCE
- CREATE OR REPLACE TABLE

## Dashboard

The Power BI dashboard presents customer retention, RFM segmentation, cohort analysis, and historical revenue distribution.

See the `dashboard` folder for the dashboard file and the `screenshots` folder for previews.

## Project Structure

```text
customer-retention-analysis/
│
├── README.md
├── queries/
├── results/
├── dashboard/
├── screenshots/
├── notebooks/
└── visuals/
```

## Project 1 Connection

| Dimension | Project 1 | Project 2 |
|---|---|---|
| Focus | Acquisition and conversion | Retention and repeat purchases |
| Dataset | Google Analytics Sample Dataset | Olist Brazilian E-Commerce |
| Key techniques | BigQuery SQL, funnel analysis | SQL, RFM and cohort analysis |
| Business question | Where do users disengage? | Do customers return? |

Together, these projects explore different stages of the e-commerce customer journey, from website activity and purchasing behaviour to customer retention.

## Author

**Mohd Imran**

Data Analytics | Product & Business Analytics

[LinkedIn](https://www.linkedin.com/in/mohd-imran-55348a325)
