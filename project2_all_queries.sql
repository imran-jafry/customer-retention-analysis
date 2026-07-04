-- ================================================================
-- Project  : Customer Retention & Repeat Purchase Analysis
-- Dataset  : Olist Brazilian E-Commerce Dataset (Kaggle)
-- Platform : Google BigQuery
-- Period   : 2017 to 2018
-- Created by: Mohd Imran
-- ================================================================


-- Query 1: Dataset Overview — Understanding Table Sizes
-- First step on any new dataset. Verify row counts match
-- what we saw in Excel before writing any analysis queries.

SELECT
  'orders' AS table_name, COUNT(*) AS row_count
FROM `olist_ecommerce.orders_dataset`
UNION ALL
SELECT 'customers', COUNT(*) FROM `olist_ecommerce.customers_dataset`
UNION ALL
SELECT 'order_items', COUNT(*) FROM `olist_ecommerce.order_items_dataset`
UNION ALL
SELECT 'order_payments', COUNT(*) FROM `olist_ecommerce.order_payments_dataset`
UNION ALL
SELECT 'products', COUNT(*) FROM `olist_ecommerce.product_dataset`
UNION ALL
SELECT 'order_reviews', COUNT(*) FROM `olist_ecommerce.order_review`
UNION ALL
SELECT 'sellers', COUNT(*) FROM `olist_ecommerce.sellers_dataset`
UNION ALL
SELECT 'category_translation', COUNT(*) FROM `olist_ecommerce.category_name_translation`;


-- Query 2: Order Status Distribution
-- Before any analysis we need to know what percentage of orders
-- were actually delivered. Cancelled and pending orders should
-- never be counted as real customer purchases.
-- Finding: 97.02% delivered — clean dataset for analysis.

SELECT
  order_status,
  COUNT(*) AS total_orders,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM `olist_ecommerce.orders_dataset`
GROUP BY order_status
ORDER BY total_orders DESC;


-- Query 3: Order Volume by Year and Month
-- Understanding the data timeline before building cohorts.
-- Key finding: 2016 had very few orders — excluded from analysis.
-- Main analysis restricted to 2017 and 2018 only.

SELECT
  EXTRACT(YEAR FROM TIMESTAMP(order_purchase_timestamp)) AS order_year,
  EXTRACT(MONTH FROM TIMESTAMP(order_purchase_timestamp)) AS order_month,
  COUNT(*) AS total_orders,
  COUNT(DISTINCT customer_id) AS unique_customers
FROM `olist_ecommerce.orders_dataset`
WHERE order_status = 'delivered'
GROUP BY order_year, order_month
ORDER BY order_year, order_month;


-- Query 4: Customer ID vs Unique Customer ID
-- Critical discovery: customer_id is unique per ORDER not per PERSON.
-- customer_unique_id is the true unique customer identifier.
-- Using customer_id for retention analysis would overcount customers.
-- This is a common real-world data design pattern.

SELECT
  COUNT(*) AS total_customer_id_rows,
  COUNT(DISTINCT customer_id) AS distinct_customer_ids,
  COUNT(DISTINCT customer_unique_id) AS distinct_unique_customers,
  COUNT(*) - COUNT(DISTINCT customer_unique_id) AS difference
FROM `olist_ecommerce.customers_dataset`;


-- Query 5: First Multi-Table JOIN — Connection Verification
-- Testing that orders, customers, and payments tables
-- join correctly before building the master table.
-- Checking for NULLs in key fields after joining.

SELECT
  o.order_id,
  c.customer_unique_id,
  o.order_purchase_timestamp,
  o.order_status,
  p.payment_value
FROM `olist_ecommerce.orders_dataset` o
LEFT JOIN `olist_ecommerce.customers_dataset` c
  ON o.customer_id = c.customer_id
LEFT JOIN `olist_ecommerce.order_payments_dataset` p
  ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
LIMIT 20;


-- Query 6: Repeat Purchase Rate — Baseline Metric
-- The headline finding of the entire project.
-- Only 3% of customers ever made a second purchase.
-- Industry average for e-commerce is 20-30%.

SELECT
  total_customers,
  repeat_customers,
  ROUND(repeat_customers * 100.0 / total_customers, 2) AS repeat_purchase_rate_pct,
  single_purchase_customers,
  ROUND(single_purchase_customers * 100.0 / total_customers, 2) AS single_purchase_rate_pct
FROM (
  SELECT
    COUNT(DISTINCT customer_unique_id) AS total_customers,
    COUNTIF(order_count > 1) AS repeat_customers,
    COUNTIF(order_count = 1) AS single_purchase_customers
  FROM (
    SELECT
      c.customer_unique_id,
      COUNT(o.order_id) AS order_count
    FROM `olist_ecommerce.orders_dataset` o
    LEFT JOIN `olist_ecommerce.customers_dataset` c
      ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
  )
);


-- Query 7: Data Quality Check
-- Before building the master table, checking for data issues.
-- Finding: Very clean data — only 5 problematic rows total.
-- These are handled by WHERE clause filters in the master table.

SELECT
  COUNT(*) AS total_delivered_orders,
  COUNTIF(c.customer_unique_id IS NULL) AS missing_customer_id,
  COUNTIF(p.payment_value IS NULL) AS missing_payment,
  COUNTIF(p.payment_value = 0) AS zero_payment,
  COUNTIF(o.order_purchase_timestamp IS NULL) AS missing_date
FROM `olist_ecommerce.orders_dataset` o
LEFT JOIN `olist_ecommerce.customers_dataset` c
  ON o.customer_id = c.customer_id
LEFT JOIN `olist_ecommerce.order_payments_dataset` p
  ON o.order_id = p.order_id
WHERE o.order_status = 'delivered';


-- Query 8: Customer Master Table — Foundation of All Analysis
-- This is the most important query in the project.
-- Creates a single clean table summarizing every customer's
-- complete purchase history. All subsequent analysis reads
-- from this table instead of re-joining 4 tables every time.
--
-- Key decisions:
-- 1. Filter delivered orders only — no cancelled/pending
-- 2. Years 2017-2018 only — 2016 had too few orders
-- 3. Exclude NULL and zero payment values — data errors
-- 4. Snapshot date: 2018-09-01 (dataset end date)
--    Used for days_since_last_purchase calculation

CREATE OR REPLACE TABLE `olist_ecommerce.customer_master` AS

SELECT
  c.customer_unique_id,
  COUNT(DISTINCT o.order_id) AS total_orders,
  ROUND(SUM(p.payment_value), 2) AS total_revenue,
  ROUND(AVG(p.payment_value), 2) AS avg_order_value,
  MIN(DATE(o.order_purchase_timestamp)) AS first_purchase_date,
  MAX(DATE(o.order_purchase_timestamp)) AS last_purchase_date,
  DATE_DIFF(
    MAX(DATE(o.order_purchase_timestamp)),
    MIN(DATE(o.order_purchase_timestamp)),
    DAY) AS days_between_first_last,
  DATE_DIFF(
    DATE('2018-09-01'),
    MAX(DATE(o.order_purchase_timestamp)),
    DAY) AS days_since_last_purchase,
  EXTRACT(YEAR FROM MIN(o.order_purchase_timestamp)) AS acquisition_year,
  EXTRACT(MONTH FROM MIN(o.order_purchase_timestamp)) AS acquisition_month
FROM `olist_ecommerce.orders_dataset` o
LEFT JOIN `olist_ecommerce.customers_dataset` c
  ON o.customer_id = c.customer_id
LEFT JOIN `olist_ecommerce.order_payments_dataset` p
  ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
  AND c.customer_unique_id IS NOT NULL
  AND p.payment_value IS NOT NULL
  AND p.payment_value > 0
  AND EXTRACT(YEAR FROM o.order_purchase_timestamp) IN (2017, 2018)
GROUP BY c.customer_unique_id;


-- Query 9: Customer Master Verification
-- After building master table, verify numbers match
-- our earlier baseline calculations.
-- Key metrics: 93,104 customers, 3% repeat rate, $165 avg CLV

SELECT
  COUNT(*) AS total_customers,
  COUNTIF(total_orders = 1) AS single_purchase,
  COUNTIF(total_orders > 1) AS repeat_purchase,
  ROUND(COUNTIF(total_orders > 1) * 100.0 / COUNT(*), 2) AS repeat_rate_pct,
  ROUND(AVG(total_revenue), 2) AS avg_customer_revenue,
  ROUND(AVG(avg_order_value), 2) AS avg_order_value,
  ROUND(AVG(days_since_last_purchase), 0) AS avg_days_since_purchase,
  MAX(total_orders) AS most_orders_by_one_customer
FROM `olist_ecommerce.customer_master`;


-- Query 10: RFM Segmentation — Customer Value Classification
-- RFM = Recency, Frequency, Monetary
-- Each customer scored 1-5 on each dimension using NTILE.
-- Segments adjusted for Olist's data distribution where
-- 97% of customers have frequency = 1 — making standard
-- frequency scoring meaningless. Segments weighted toward
-- recency and monetary value instead.
--
-- NTILE(5): divides customers into 5 equal buckets.
-- Recency: lower days = better = higher score (ORDER BY DESC)
-- Frequency: higher orders = better (ORDER BY ASC)
-- Monetary: higher spend = better (ORDER BY ASC)

CREATE OR REPLACE TABLE `olist_ecommerce.rfm_segments` AS

WITH rfm_base AS (
  SELECT
    customer_unique_id,
    days_since_last_purchase AS recency,
    total_orders AS frequency,
    total_revenue AS monetary
  FROM `olist_ecommerce.customer_master`
),
rfm_scores AS (
  SELECT
    customer_unique_id,
    recency,
    frequency,
    monetary,
    NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
    NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
    NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
  FROM rfm_base
),
rfm_segments AS (
  SELECT
    customer_unique_id,
    recency,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    CONCAT(CAST(r_score AS STRING),
           CAST(f_score AS STRING),
           CAST(m_score AS STRING)) AS rfm_score,
    (r_score + f_score + m_score) AS total_rfm_score,
    CASE
      WHEN frequency >= 2 AND r_score >= 4 AND m_score >= 4
        THEN 'Champions'
      WHEN frequency >= 2 AND r_score >= 3
        THEN 'Loyal Customers'
      WHEN frequency = 1 AND r_score >= 4 AND m_score >= 4
        THEN 'High Value New'
      WHEN frequency = 1 AND r_score >= 4 AND m_score < 4
        THEN 'New Customers'
      WHEN frequency >= 2 AND r_score <= 2
        THEN 'At Risk - Repeat'
      WHEN frequency = 1 AND r_score >= 3 AND m_score >= 3
        THEN 'Potential Loyalists'
      WHEN frequency = 1 AND r_score = 2
        THEN 'Hibernating'
      WHEN frequency = 1 AND r_score = 1
        THEN 'Lost'
      WHEN r_score = 3 AND m_score <= 2
        THEN 'Low Value Mid-Recency'
      ELSE 'Uncategorized'
    END AS customer_segment
  FROM rfm_scores
)

SELECT * FROM rfm_segments;


-- Query 11: RFM Segment Summary
-- Business summary of each segment for dashboard and
-- stakeholder presentation.

SELECT
  customer_segment,
  COUNT(*) AS customer_count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_of_customers,
  ROUND(AVG(recency), 0) AS avg_recency_days,
  ROUND(AVG(frequency), 2) AS avg_orders,
  ROUND(AVG(monetary), 2) AS avg_revenue,
  ROUND(SUM(monetary), 2) AS total_segment_revenue,
  COUNTIF(frequency >= 2) AS repeat_buyers_in_segment
FROM `olist_ecommerce.rfm_segments`
GROUP BY customer_segment
ORDER BY total_segment_revenue DESC;


-- Query 12: Time Between First and Second Purchase
-- Using ROW_NUMBER to number each customer's orders
-- chronologically, then self-joining to find the gap
-- between order 1 and order 2.
--
-- ROW_NUMBER(): assigns sequential number per customer
-- PARTITION BY: resets count for each customer
-- Self JOIN: joins table to itself — left side = first purchase,
--            right side = second purchase for same customer
--
-- Key finding: 50% of repeat buyers return within 30 days.
-- This is the critical retention window.

WITH customer_orders AS (
  SELECT
    c.customer_unique_id,
    DATE(o.order_purchase_timestamp) AS purchase_date,
    ROW_NUMBER() OVER (
      PARTITION BY c.customer_unique_id
      ORDER BY o.order_purchase_timestamp
    ) AS order_number
  FROM `olist_ecommerce.orders_dataset` o
  JOIN `olist_ecommerce.customers_dataset` c
    ON o.customer_id = c.customer_id
  WHERE o.order_status = 'delivered'
    AND EXTRACT(YEAR FROM o.order_purchase_timestamp) IN (2017, 2018)
),
first_second AS (
  SELECT
    a.customer_unique_id,
    a.purchase_date AS first_purchase,
    b.purchase_date AS second_purchase,
    DATE_DIFF(b.purchase_date, a.purchase_date, DAY) AS days_to_second_purchase
  FROM customer_orders a
  JOIN customer_orders b
    ON a.customer_unique_id = b.customer_unique_id
    AND a.order_number = 1
    AND b.order_number = 2
)

SELECT
  COUNT(*) AS repeat_customers,
  ROUND(AVG(days_to_second_purchase), 0) AS avg_days_to_second_purchase,
  MIN(days_to_second_purchase) AS min_days,
  MAX(days_to_second_purchase) AS max_days,
  COUNTIF(days_to_second_purchase <= 30) AS returned_within_30_days,
  COUNTIF(days_to_second_purchase BETWEEN 31 AND 60) AS returned_31_to_60_days,
  COUNTIF(days_to_second_purchase BETWEEN 61 AND 90) AS returned_61_to_90_days,
  COUNTIF(days_to_second_purchase > 90) AS returned_after_90_days
FROM first_second;


-- Query 13: Repeat Purchase Rate by Product Category
-- Identifying which categories drive repeat behavior.
-- COALESCE handles NULL category names from translation join.
-- HAVING COUNT > 100 filters statistically insignificant categories.
--
-- Key finding: Home appliances leads at 7.27% — customers
-- furnishing homes buy multiple items over time.
-- Health and beauty surprisingly low at 1.67%.
--
-- Note: category_name_translation has no header row in BigQuery.
-- Column names are string_field_0 (Portuguese) and
-- string_field_1 (English) due to CSV upload without headers.

WITH customer_category AS (
  SELECT
    c.customer_unique_id,
    COALESCE(t.string_field_1, 'unknown') AS category,
    COUNT(DISTINCT o.order_id) AS orders_in_category
  FROM `olist_ecommerce.orders_dataset` o
  JOIN `olist_ecommerce.customers_dataset` c
    ON o.customer_id = c.customer_id
  JOIN `olist_ecommerce.order_items_dataset` oi
    ON o.order_id = oi.order_id
  JOIN `olist_ecommerce.product_dataset` p
    ON oi.product_id = p.product_id
  LEFT JOIN `olist_ecommerce.category_name_translation` t
    ON p.product_category_name = t.string_field_0
  WHERE o.order_status = 'delivered'
    AND EXTRACT(YEAR FROM o.order_purchase_timestamp) IN (2017, 2018)
    AND t.string_field_0 != 'product_category_name'
  GROUP BY c.customer_unique_id, category
),
category_stats AS (
  SELECT
    category,
    COUNT(DISTINCT customer_unique_id) AS total_customers,
    COUNTIF(orders_in_category > 1) AS repeat_customers,
    ROUND(COUNTIF(orders_in_category > 1) * 100.0 /
      COUNT(DISTINCT customer_unique_id), 2) AS repeat_rate_pct
  FROM customer_category
  GROUP BY category
  HAVING COUNT(DISTINCT customer_unique_id) > 100
)

SELECT *
FROM category_stats
ORDER BY repeat_rate_pct DESC
LIMIT 15;


-- Query 14: Review Score vs Repeat Purchase Rate
-- Testing hypothesis: satisfied customers return more often.
-- Surprising finding: difference between 5-star and 1-star
-- repeat rate is less than 1 percentage point.
-- Conclusion: on Olist, platform convenience drives repeat
-- purchase more than satisfaction score.
-- 1-star customers have highest avg revenue ($204) —
-- they are high-value buyers with high expectations.

SELECT
  r.review_score,
  COUNT(DISTINCT c.customer_unique_id) AS total_customers,
  COUNTIF(cm.total_orders > 1) AS repeat_customers,
  ROUND(COUNTIF(cm.total_orders > 1) * 100.0 /
    COUNT(DISTINCT c.customer_unique_id), 2) AS repeat_rate_pct,
  ROUND(AVG(cm.total_revenue), 2) AS avg_customer_revenue
FROM `olist_ecommerce.orders_dataset` o
JOIN `olist_ecommerce.customers_dataset` c
  ON o.customer_id = c.customer_id
JOIN `olist_ecommerce.order_review` r
  ON o.order_id = r.order_id
JOIN `olist_ecommerce.customer_master` cm
  ON c.customer_unique_id = cm.customer_unique_id
WHERE o.order_status = 'delivered'
  AND EXTRACT(YEAR FROM o.order_purchase_timestamp) IN (2017, 2018)
GROUP BY r.review_score
ORDER BY r.review_score DESC;


-- Query 15: Cohort Retention Analysis
-- Groups customers by their first purchase month (cohort).
-- Tracks what percentage returned in subsequent months.
-- Five CTEs working together:
--   first_purchase    → each customer's first purchase month
--   customer_activity → every month each customer was active
--   cohort_data       → months since first purchase per customer
--   cohort_size       → how many customers in each cohort
--   cohort_retention  → how many returned each subsequent month
--
-- DATE_TRUNC: rounds dates to first day of month for grouping
--
-- Key finding: Month 1 retention never exceeds 0.72%
-- across any cohort. Industry benchmark is 20-30%.
-- October 2017 cohort has best retention. December worst.

CREATE OR REPLACE TABLE `olist_ecommerce.cohort_retention` AS

WITH first_purchase AS (
  SELECT
    c.customer_unique_id,
    DATE_TRUNC(MIN(DATE(o.order_purchase_timestamp)), MONTH) AS cohort_month
  FROM `olist_ecommerce.orders_dataset` o
  JOIN `olist_ecommerce.customers_dataset` c
    ON o.customer_id = c.customer_id
  WHERE o.order_status = 'delivered'
    AND EXTRACT(YEAR FROM o.order_purchase_timestamp) IN (2017, 2018)
  GROUP BY c.customer_unique_id
),
customer_activity AS (
  SELECT
    c.customer_unique_id,
    DATE_TRUNC(DATE(o.order_purchase_timestamp), MONTH) AS activity_month
  FROM `olist_ecommerce.orders_dataset` o
  JOIN `olist_ecommerce.customers_dataset` c
    ON o.customer_id = c.customer_id
  WHERE o.order_status = 'delivered'
    AND EXTRACT(YEAR FROM o.order_purchase_timestamp) IN (2017, 2018)
  GROUP BY c.customer_unique_id, activity_month
),
cohort_data AS (
  SELECT
    fp.customer_unique_id,
    fp.cohort_month,
    ca.activity_month,
    DATE_DIFF(ca.activity_month, fp.cohort_month, MONTH) AS months_since_first_purchase
  FROM first_purchase fp
  JOIN customer_activity ca
    ON fp.customer_unique_id = ca.customer_unique_id
),
cohort_size AS (
  SELECT
    cohort_month,
    COUNT(DISTINCT customer_unique_id) AS cohort_customers
  FROM first_purchase
  GROUP BY cohort_month
),
cohort_retention AS (
  SELECT
    cd.cohort_month,
    cd.months_since_first_purchase,
    COUNT(DISTINCT cd.customer_unique_id) AS retained_customers
  FROM cohort_data cd
  GROUP BY cohort_month, months_since_first_purchase
)

SELECT
  cr.cohort_month,
  cs.cohort_customers,
  cr.months_since_first_purchase,
  cr.retained_customers,
  ROUND(cr.retained_customers * 100.0 / cs.cohort_customers, 2) AS retention_rate_pct
FROM cohort_retention cr
JOIN cohort_size cs
  ON cr.cohort_month = cs.cohort_month
WHERE cr.months_since_first_purchase <= 12
ORDER BY cr.cohort_month, cr.months_since_first_purchase;


-- Query 16: Cohort Data Export for Power BI Heatmap
-- Formats cohort data for Power BI matrix visual.
-- FORMAT_DATE converts dates to readable labels.
-- month_label converts numbers to M1, M2 etc.
-- cohort_sort keeps sortable version for correct ordering.
-- Month 0 excluded — always 100% by definition.

SELECT
  FORMAT_DATE('%b %Y', cohort_month) AS cohort,
  FORMAT_DATE('%Y-%m', cohort_month) AS cohort_sort,
  months_since_first_purchase AS month_number,
  CONCAT('M', CAST(months_since_first_purchase AS STRING)) AS month_label,
  retention_rate_pct
FROM `olist_ecommerce.cohort_retention`
WHERE months_since_first_purchase BETWEEN 1 AND 12
ORDER BY cohort_month, months_since_first_purchase;


-- Query 17: Customer Lifetime Value by Segment
-- Joins RFM segments with customer master to calculate
-- CLV metrics per segment.
-- Answers Business Question 10: which segment to prioritize?
-- NULLIF prevents division by zero errors.
--
-- Key finding: High Value New segment has highest total revenue
-- at $4.34M (28.24% of all revenue) despite avg CLV of $302.
-- Priority recommendation: convert High Value New to repeat buyers.

SELECT
  r.customer_segment,
  COUNT(*) AS customer_count,
  ROUND(AVG(cm.total_revenue), 2) AS avg_clv,
  ROUND(AVG(cm.total_orders), 2) AS avg_orders,
  ROUND(AVG(cm.avg_order_value), 2) AS avg_order_value,
  ROUND(AVG(cm.days_since_last_purchase), 0) AS avg_days_inactive,
  ROUND(SUM(cm.total_revenue), 2) AS total_segment_revenue,
  ROUND(SUM(cm.total_revenue) * 100.0 /
    SUM(SUM(cm.total_revenue)) OVER(), 2) AS revenue_share_pct
FROM `olist_ecommerce.rfm_segments` r
JOIN `olist_ecommerce.customer_master` cm
  ON r.customer_unique_id = cm.customer_unique_id
GROUP BY r.customer_segment
ORDER BY avg_clv DESC;


-- Query 18: Time to Return Window — Export for Power BI
-- Buckets repeat customers by how quickly they returned.
-- Used for donut/bar chart in dashboard.

WITH customer_orders AS (
  SELECT
    c.customer_unique_id,
    DATE(o.order_purchase_timestamp) AS purchase_date,
    ROW_NUMBER() OVER (
      PARTITION BY c.customer_unique_id
      ORDER BY o.order_purchase_timestamp
    ) AS order_number
  FROM `olist_ecommerce.orders_dataset` o
  JOIN `olist_ecommerce.customers_dataset` c
    ON o.customer_id = c.customer_id
  WHERE o.order_status = 'delivered'
    AND EXTRACT(YEAR FROM o.order_purchase_timestamp) IN (2017, 2018)
),
first_second AS (
  SELECT
    DATE_DIFF(b.purchase_date, a.purchase_date, DAY) AS days_to_second_purchase,
    CASE
      WHEN DATE_DIFF(b.purchase_date, a.purchase_date, DAY) <= 30
        THEN '0-30 days'
      WHEN DATE_DIFF(b.purchase_date, a.purchase_date, DAY) <= 60
        THEN '31-60 days'
      WHEN DATE_DIFF(b.purchase_date, a.purchase_date, DAY) <= 90
        THEN '61-90 days'
      ELSE '90+ days'
    END AS return_window
  FROM customer_orders a
  JOIN customer_orders b
    ON a.customer_unique_id = b.customer_unique_id
    AND a.order_number = 1
    AND b.order_number = 2
)

SELECT
  return_window,
  COUNT(*) AS customers,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_of_repeat_customers
FROM first_second
GROUP BY return_window
ORDER BY MIN(days_to_second_purchase);


-- Query 19: KPI Summary for Power BI Cards
-- Single row table with all headline metrics.
-- Hard-coded values calculated from queries above.

SELECT
  93104 AS total_customers,
  2789 AS repeat_customers,
  3.0 AS repeat_rate_pct,
  90315 AS single_purchase_customers,
  165.15 AS avg_customer_ltv,
  157.61 AS avg_order_value,
  239 AS avg_days_since_purchase,
  15384376.44 AS total_revenue,
  15 AS max_orders_one_customer;


-- End of file — 19 queries total
-- Created by Mohd Imran
-- Dataset: Olist Brazilian E-Commerce (Kaggle)
-- Platform: Google BigQuery
