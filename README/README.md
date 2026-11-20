# Customer Retention & Repeat Purchase Analysis

Analyzed customer purchasing behaviour using the Olist Brazilian E-Commerce Dataset to understand repeat purchasing, customer value, retention patterns, and customer segmentation through SQL, Python, and Power BI.

## Project Overview

**Business Question:** How can an e-commerce business understand its customer base, identify valuable customer segments, and evaluate repeat-purchase behaviour?

This project examines historical customer purchasing patterns using customer-level aggregation, RFM segmentation, cohort analysis, and repeat-purchase analysis. The objective is to identify behavioural patterns that can inform customer retention strategies and business decision-making.

**Project Type:** Portfolio Analytics Project  
**Tools:** SQL, Google BigQuery, Python, Pandas, Power BI

## Dataset

- **Source:** Olist Brazilian E-Commerce Dataset — Kaggle
- **Period:** 2017–2018
- **Tables used:** 7 relational tables
- **Total orders in source dataset:** 99,441
- **Unique customers in source dataset:** 96,096
- **Analysis population:** 93,104 customers with delivered orders and valid payment records

Customer-level analysis uses `customer_unique_id` to identify individuals across multiple orders rather than treating order-level `customer_id` records as separate customers.

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

| Metric | Result |
|---|---:|
| Customers analyzed | 93,104 |
| Repeat customers | 2,789 |
| Repeat-purchase rate | ~3.0% |
| Single-purchase customers | ~97.0% |

Repeat purchases were relatively uncommon within the observed dataset period.

Customers acquired near the end of the observation period had less time to make another purchase, meaning the observed repeat-purchase rate should not be interpreted as a fully observed long-term retention rate.

### 2. RFM Customer Segmentation

Applied Recency, Frequency, and Monetary analysis to categorize customers into nine rule-based segments:

- Champions
- Loyal Customers
- Potential Loyalists
- At Risk Repeat
- High Value New
- New Customers
- Hibernating
- Lost
- Low Value Mid-Recency

The segmentation provides a way to compare historical purchasing behaviour and revenue contribution across customer groups.

**Key observation:** The High Value New segment contributed approximately 28.24% of historical revenue. This reflects the segment's spending-based classification and does not indicate future revenue potential.

Customer frequency was highly concentrated among one-time buyers, requiring adjusted segmentation logic. NTILE-based scoring may also split customers with tied values across score boundaries.

### 3. Cohort Retention Analysis

Customers were grouped by their first purchase month to examine repeat-purchase activity across subsequent months.

- 20 monthly cohorts analyzed.
- Highest observed Month 1 retention: October 2017 (~0.72%).
- Lowest observed Month 1 retention: February 2017 (~0.18%).
- Month 1 retention remained below 1% across observed cohorts.
- Average of the 19 observable Month 1 cohort values: ~0.48%.

These figures represent historical monthly purchasing activity rather than cumulative retention.

Later cohorts had shorter observation periods, and the August 2018 cohort did not have a complete Month 1 observation window.

### 4. Time Between Purchases

Examined the time between customers' first and subsequent purchases.

- 1,412 repeat buyers had a recorded purchase gap of 0–30 days.
- Approximately 50.6% of repeat buyers fell within this interval.

This describes purchase timing among customers who purchased more than once, not the probability of a customer returning within 30 days.

### 5. Product Category Analysis

Compared same-category repeat-purchase rates across product categories.

| Product Category | Observed Same-Category Repeat Rate |
|---|---:|
| Home Appliances | ~7.27% |
| Fashion Bags | ~2.91% |
| Bed Bath Table | ~2.72% |
| Sports Leisure | ~2.32% |
| Health Beauty | ~1.67% |

The observed differences highlight variation in repeat purchasing across categories. These patterns do not establish the underlying reasons for customer behaviour.

### 6. Review Score Analysis

Explored the relationship between review scores and repeat-purchase behaviour.

The initial customer-level comparison contained duplicate counting issues caused by customers having multiple orders and reviews. Therefore, this comparison is not presented as a validated finding.

## Potential Business Applications

The analysis can help an e-commerce business:

- Identify customer segments with different purchasing patterns.
- Compare historical revenue contributions across customer segments.
- Monitor repeat-purchase behaviour over time.
- Evaluate retention patterns across acquisition cohorts.
- Identify product categories with comparatively higher same-category repeat-purchase rates.
- Develop hypotheses for targeted customer engagement and retention strategies.

These are potential applications of the analysis, not implemented campaigns or measured business outcomes.

## Tools & Technologies

| Tool | Purpose |
|---|---|
| Google BigQuery | SQL analysis and data extraction |
| SQL | JOINs, CTEs, aggregations, window functions and customer-level analysis |
| Python | Exploratory data analysis |
| Pandas | Data manipulation |
| Matplotlib & Seaborn | Data visualization |
| Power BI | Interactive dashboard development |
| Kaggle | Dataset source |

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

## Data Challenges & Approach

| Challenge | Approach |
|---|---|
| `customer_id` vs `customer_unique_id` | Used customer-level identifiers for repeat-purchase analysis. |
| Relational dataset structure | Joined relevant tables using their associated keys. |
| Product category names in Portuguese | Used the category translation table. |
| Sparse historical data | Interpreted retention within the observed 2017–2018 period. |
| Customer frequency imbalance | Adjusted segmentation logic to account for the high proportion of one-time buyers. |
| Missing or zero payment values | Applied payment-value filters where appropriate. |
| Customer duplication across joins | Used customer-level aggregation and identified areas requiring additional validation. |

## Dashboard

The Power BI dashboard visualizes:

- Customer retention and repeat-purchase KPIs
- RFM customer segmentation
- Historical revenue distribution
- Cohort retention
- Time between purchases
- Same-category repeat-purchase behaviour

See the `dashboard` folder for the Power BI file and the `screenshots` folder for dashboard previews.

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
| Dataset | Google Analytics Sample Dataset | Olist Brazilian E-Commerce Dataset |
| Key techniques | BigQuery SQL, funnel analysis | SQL, RFM and cohort analysis |
| Business question | Where do users disengage? | Do customers return? |

Together, these projects examine different stages of the e-commerce customer journey, from website activity and purchasing behaviour to customer retention.

## Author

**Mohd Imran**

Data Analytics | Product & Business Analytics

[LinkedIn](https://www.linkedin.com/in/mohd-imran-55348a325)
