# Northwind-SQL-Analysis
End - to - end SQL business analysis of the Northwind database using PostgreSQL

```markdown
# 🏪 Northwind Business Intelligence Analysis — SQL Project

Author: Ayomide Folorunsho
Database: PostgreSQL
Tools: PostgreSQL · pgAdmin 4 · GitHub
Dataset: Northwind Trading Company (Downloaded from Kaggle) 

---

## 📖 Table of Contents
- [Project Overview](#project-overview)
- [Objectives](#objectives)
- [Tools and Database](#tools-and-database)
- [Database Schema](#database-schema)
- [Project Structure](#project-structure)
- [Key SQL Concepts Demonstrated](#key-sql-concepts-demonstrated)
- [Section Breakdown](#section-breakdown)
- [Key Findings](#key-findings)
- [How to Use This Project](#how-to-use-this-project)
- [Author](#author)

---

## 📋 Project Overview

This is my second SQL portfolio project, building on the foundation of my first 
project where I designed a logistics relational database from scratch. In this 
project, I worked with the **Northwind database** — a well-known sample dataset 
representing a trading company that buys and sells specialty food products globally.

The Northwind database was downloaded from **Kaggle** and installed locally using
**PostgreSQL** and **pgAdmin 4**. The database was restored into a new PostgreSQL
instance, making all 14 tables immediately available for analysis without any
manual schema building or data entry. 

Rather than building the database myself, this project simulates a real-world 
analyst scenario: being handed an existing database and tasked with extracting 
meaningful business insights from it. Every query was written to answer a genuine 
business question, progressing from foundational analysis in early sections to 
advanced window functions and multi-CTE queries in the final section.

---

## 📊 Project Summary

- 14 relational tables analysed
- 6 business analysis sections
- 19 SQL queries
- Customer, employee, product, supplier and shipping analysis
- Revenue trend analysis using advanced SQL
- Built using PostgreSQL and pgAdmin 4
- Demonstrates CTEs, Window Functions, Ranking Functions and Advanced Aggregations

---

## 🎯 Objectives

- Identify the most valuable customers by revenue and location
- Evaluate employee sales performance, age, and years of experience
- Analyse product and category performance across the catalogue
- Assess supplier contribution to revenue and product variety
- Measure shipping efficiency and late delivery rates by shipper and country
- Uncover revenue trends over time using advanced SQL techniques

---

## 🛠️ Tools and Database

| Tool | Purpose |
|---|---|
| PostgreSQL | Database engine |
| pgAdmin 4 | Query interface and database management |
| GitHub | Version control and portfolio publishing |

**Database:** Northwind (PostgreSQL-compatible version)
**Source:** [pthom/northwind_psql](https://github.com/pthom/northwind_psql)

```

## 🗂️ Database Schema

The Northwind database contains 14 tables. The key tables used in this analysis are:

| Table | Description |
|---|---|
| `customers` | Company names, contact details, city and country |
| `orders` | Every order placed including dates and shipping info |
| `order_details` | Line items per order — product, quantity, price, discount |
| `products` | Product names, unit prices, and stock levels |
| `categories` | Product category groupings |
| `employees` | Staff details including hire date and birth date |
| `suppliers` | Supplier company names and countries |
| `shippers` | Shipping company names used to fulfil orders |

**Key Relationships:**
- `customers` → `orders` → `order_details` → `products`
- `products` → `categories` and `suppliers`
- `orders` → `employees` (who handled the order)
- `orders` → `shippers` (via `ship_via` foreign key)

![Database Schema](images/Database Schema 1.png)

![Database Schema](images/Database Schema 2.png)

## ⚙️ Database Setup

1. Downloaded the Northwind dataset from Kaggle
2. Installed PostgreSQL and set up a local server
3. Created a new database called `northwind` in pgAdmin 4
4. Ran the `northwind.sql` file to populate all 14 tables
5. Verified table relationships and row counts before querying
6. Wrote and executed all analysis queries in pgAdmin 4
---

## Project Structure

| Section | Focus | Queries |
|---|---|---|
| Section 1 | Customer Analysis | 4 queries |
| Section 2 | Employee Performance Analysis | 1 combined query |
| Section 3 | Product and Category Analysis | 3 queries |
| Section 4 | Supplier Analysis | 3 queries |
| Section 5 | Shipping and Delivery Performance | 2 queries |
| Section 6 | Advanced Insights and Revenue Trends | 6 queries |

---

## Key SQL Concepts Demonstrated

| Concept | Where Used |
|---|---|
| Multi-table JOINs (INNER, LEFT, CROSS) | All sections |
| GROUP BY and aggregate functions | All sections |
| CASE WHEN segmentation | Sections 1, 6 |
| RANK() window function | Sections 2, 3 |
| NTILE(4) window function | Section 6 |
| SUM() OVER for running totals | Section 6 |
| PARTITION BY | Section 3 |
| Common Table Expressions (CTEs) | Sections 1, 6 |
| Correlated subqueries | Section 6 |
| PERCENTILE_CONT for statistical segmentation | Section 1 |
| Date functions (EXTRACT, AGE, DATE_PART, TO_CHAR) | Sections 2, 5, 6 |
| NULLIF for division protection | Section 2 |
| NULLS LAST ordering | Section 1 |

---

## 💡 Sample SQL Query

```sql
-- ====================================================================================
-- SECTION 1: CUSTOMER ANALYSIS
-- Description: Identifying the most valuable customers by revenue, and analysing
-- purchasing behaviour across cities and countries.
-- Tables Used: customers (c), orders (o), order_details (od)
-- ====================================================================================

-- ------------------------------------------------------------------------------------
-- Query 1d: Customer segmentation by spending level (High / Medium / Low)
-- Uses two CTEs:
-- customer_revenue: calculates total discounted revenue per customer
-- percentile: calculates the 75th and 50th percentile revenue boundaries
-- ------------------------------------------------------------------------------------

WITH customer_revenue AS (
    SELECT
        c.customer_id,
        c.contact_name,
        c.city,
        c.country,
        ROUND(SUM((od.unit_price * od.quantity) -
              (od.unit_price * od.quantity * od.discount))::NUMERIC, 0) AS total_revenue
    FROM customers AS c
    INNER JOIN orders AS o ON c.customer_id = o.customer_id
    INNER JOIN order_details AS od ON o.order_id = od.order_id
    GROUP BY c.customer_id, c.contact_name, c.city, c.country
),
percentile AS (
    SELECT
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY total_revenue) AS p_75,
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY total_revenue) AS p_50
    FROM customer_revenue
)
SELECT
    cr.customer_id,
    cr.contact_name,
    cr.city,
    cr.country,
    cr.total_revenue,
    CASE
        WHEN cr.total_revenue >= p.p_75 THEN 'High'
        WHEN cr.total_revenue >= p.p_50 THEN 'Medium'
        ELSE 'Low'
    END AS spending_tier
FROM customer_revenue AS cr
CROSS JOIN percentile AS p
ORDER BY total_revenue DESC NULLS LAST;
```

---

---📸 Sample Outputs

![Sample Outputs](images/Annotation 2026-06-08 123056.png)

![Sample Outputs](images/Annotation 2026-06-08 123151.png)

![Sample Outputs](images/Annotation 2026-06-08 123553.png)




## Section Breakdown

### Section 1 — Customer Analysis
**Business Question:** Who are our most valuable customers and where do they come from?

- **Query 1a:** Top 10 customers ranked by total discounted revenue, with city
  and country included for geographic context
- **Query 1b:** Revenue, total orders, and unique customer count grouped by country
  to identify the highest performing markets
- **Query 1c:** Same metrics broken down by city to surface the most active
  purchasing cities
- **Query 1d:** Customer segmentation into High, Medium, and Low spenders using
  a two-CTE approach — `customer_revenue` calculates total revenue per customer,
  `percentile` derives the 75th and 50th percentile boundaries using
  `PERCENTILE_CONT`, and customers are then categorised accordingly via
  `CASE WHEN` with a `CROSS JOIN` to make the boundaries available to every row

---

### Section 2 — Employee Performance Analysis
**Business Question:** Which employees drive the most sales and how experienced are they?

- **Query 2:** A single combined query covering all six employee metrics:
  total orders handled, total revenue generated, employee age calculated from
  birth date, years of service calculated from hire date, and revenue rank
  using `RANK()`. `AGE()` against `MAX(order_date)` is used to calculate
  age and experience relative to the last order date in the dataset.

---

### Section 3 — Product and Category Analysis
**Business Question:** What are we selling the most and which categories dominate?

- **Query 3a:** Top 10 products by total quantity sold and revenue
- **Query 3b:** Bottom 10 underperforming products by revenue — same structure
  as 3a but ordered ascending to surface the weakest performers
- **Query 3c:** Category revenue totals with each product ranked within its
  own category using `RANK()` with `PARTITION BY category_name`

---

### Section 4 — Supplier Analysis
**Business Question:** Where do our products come from and which suppliers contribute most?

- **Query 4a:** Total number of products supplied per supplier with country
  included to support geographic analysis
- **Query 4b:** Total revenue generated by each supplier's products, ordered
  descending to identify top contributors
- **Query 4c:** Bottom 5 suppliers by revenue to identify underperforming
  supplier relationships

---

### Section 5 — Shipping and Delivery Performance
**Business Question:** How efficiently are orders being fulfilled and which shippers perform best?

- **Query 5a:** Per-shipper breakdown of total orders handled, average delivery
  days, early deliveries, and late deliveries. Shippers joined via the
  `ship_via` foreign key. `EXTRACT(DAYS FROM AVG(AGE()))` used to calculate
  average delivery duration.
- **Query 5b:** Same delivery metrics grouped by destination country to
  identify which countries receive the slowest deliveries on average

---

### Section 6 — Advanced Insights and Revenue Trends
**Business Question:** What deeper patterns emerge when we look at time, segmentation, and multi-metric ranking?

- **Query 6a:** Monthly revenue aggregated across all years to identify which
  calendar months consistently generate the most revenue
- **Query 6b:** Monthly revenue broken down by year and month to track how
  revenue trended over the full dataset timeline
- **Query 6c:** Customers labelled above or below the company-wide average
  revenue using a correlated subquery inside `CASE WHEN`
- **Query 6d:** Customers divided into four equal spending tiers using
  `NTILE(4)` ordered by total revenue descending, with each tier
  labelled tier 1 through tier 4
- **Query 6e:** Cumulative running total of revenue over time using `SUM()`
  as a window function inside a CTE, ordered chronologically by year and month
- **Query 6f:** Dual-CTE query joining `highest_revenue` (revenue per country)
  and `fastest_delivery` (average delivery days per country) to identify
  countries that rank highly on both revenue and delivery speed simultaneously

---

## Key Findings

> After running the queries, replace the placeholders below with your actual results.

- **Top Customer:** [Insert company name] generated the highest revenue of [insert amount]
- **Top Country:** [Insert country] leads in total revenue with [insert amount]
  across [insert number] orders
- **Top Employee:** [Insert name] handled the most revenue at [insert amount]
  across [insert number] orders
- **Best Selling Product:** [Insert product name] ranked first by both
  quantity and revenue
- **Top Category:** [Insert category name] generated the most revenue
  across all product categories
- **Top Supplier:** [Insert supplier name] contributed the most revenue
  through their product catalogue
- **Fastest Shipper:** [Insert company name] averaged the fewest delivery days
- **Peak Revenue Month:** [Insert month] consistently generates the highest
  average revenue across all years

---
## ✅ Summary

This project demonstrates the ability to move from raw relational data
to structured business insights using SQL alone. The analysis covers
the full commercial picture of the Northwind business — from who the
best customers are, to which products drive revenue, to how efficiently
orders are being fulfilled.

## How to Use This Project

1. Install PostgreSQL and pgAdmin 4
2. Download the Northwind PostgreSQL-compatible database from
   [pthom/northwind_psql](https://github.com/pthom/northwind_psql)
3. Create a new database called `northwind` in pgAdmin
4. Restore or run the `northwind.sql` file to populate all tables
5. Open the `.sql` file from this repository in the pgAdmin Query Tool
6. Run each section independently or run the full file at once

---

## Author

**Ayomide Folorunsho**
Data Analyst | PostgreSQL | Power BI | Excel

---

*This project is part of an ongoing data analytics portfolio documenting
my learning journey from physiotherapy into data analytics.*
```

---



Everything else is ready to paste directly into your README.md file.
