-- ####################################################################################
-- PROJECT : NORTHWIND BUSINESS ANALYSIS
-- Author : Ayomide Folorunsho
-- Database : PostgreSQL (northwind)
-- Description: End-to-end SQL analysis of the Northwind trading company covering
-- customer behaviour, employee performance, product and category sales,
-- supplier contribution, shipping efficiency, and advanced revenue trends.
-- ####################################################################################


-- ====================================================================================
-- SECTION 1: CUSTOMER ANALYSIS
-- Description: Identifying the most valuable customers by revenue, and analysing
-- purchasing behaviour across cities and countries.
-- Tables Used: customers (c), orders (o), order_details (od)
-- Metrics:
-- 1: Top 10 Customers by Total Revenue
-- 2: Revenue, Orders and Customers by Country
-- 3: Orders and Customers by City
-- 4: Customer Spending Segmentation (High / Medium / Low)
-- ====================================================================================

-- ------------------------------------------------------------------------------------
-- Query 1a: Top 10 customers by total revenue generated
-- ------------------------------------------------------------------------------------

SELECT c.customer_id,
       c.contact_name,
	   c.city,
	   c.country,
	   ROUND (SUM ((od.unit_price * od.quantity) - (od.unit_price * od.quantity * od.discount)) :: NUMERIC, 0 ) AS total_revenue
FROM customers           AS c
INNER JOIN orders        AS o
ON c.customer_id = o.customer_id
INNER JOIN order_details AS od
ON o.order_id = od.order_id
GROUP BY c.customer_id,
         c.contact_name
ORDER BY total_revenue DESC 
LIMIT 10;

-- ------------------------------------------------------------------------------------
-- Query 1b: Revenue, total orders and unique customers by country
-- ------------------------------------------------------------------------------------

SELECT c.country,
	   ROUND (SUM ((od.unit_price * od.quantity) - (od.unit_price * od.quantity * od.discount)) :: NUMERIC, 0 ) AS total_revenue,
	   COUNT (DISTINCT od.order_id)                                                                             AS total_orders,
	   COUNT (DISTINCT c.customer_id)                                                                           AS total_customers
FROM customers          AS c
LEFT JOIN orders        AS o
ON c.customer_id = o.customer_id
LEFT JOIN order_details AS od
ON o.order_id = od.order_id	   
GROUP BY c.country
ORDER BY total_revenue DESC;

-- ------------------------------------------------------------------------------------
-- Query 1c: Total orders and unique customers by city
-- ------------------------------------------------------------------------------------

SELECT c.city,
       ROUND (SUM ((od.unit_price * od.quantity) - (od.unit_price * od.quantity * od.discount)) :: NUMERIC, 0 ) AS total_revenue,
	   COUNT (DISTINCT od.order_id)                                                                             AS total_orders,
	   COUNT (DISTINCT c.customer_id)                                                                           AS total_customers
FROM customers          AS c
LEFT JOIN orders        AS o
ON c.customer_id = o.customer_id
LEFT JOIN order_details AS od
ON o.order_id = od.order_id	   
GROUP BY c.city
ORDER BY total_revenue DESC, total_orders DESC;

-- ------------------------------------------------------------------------------------
-- Query 1d: Customer segmentation by spending level (High / Medium / Low)
-- ------------------------------------------------------------------------------------

WITH customer_revenue AS (
                           SELECT 
							   c.customer_id,
							   c.contact_name,
							   c.city,
							   c.country,
							   ROUND (SUM ((od.unit_price * od.quantity) - (od.unit_price * od.quantity * od.discount)) :: NUMERIC, 0 ) AS total_revenue
					       FROM customers          AS c
					       LEFT JOIN orders        AS o
						   ON c.customer_id = o.customer_id
						   LEFT JOIN order_details AS od
						   ON o.order_id = od.order_id	
						   GROUP BY c.customer_id,
					                c.contact_name,
					                c.city,
					                c.country
                          ),

    percentile AS (
                   SELECT PERCENTILE_CONT (.75) WITHIN GROUP (ORDER BY total_revenue) AS p_75,
				          PERCENTILE_CONT (.50) WITHIN GROUP (ORDER BY total_revenue) AS p_50
				   FROM customer_revenue
                  )

SELECT cr.customer_id,
	   cr.contact_name,
	   cr.city,
	   cr.country,
	   cr.total_revenue,   
	   CASE 
	       WHEN cr.total_revenue >= p.p_75 THEN 'high'
		   WHEN cr.total_revenue >= p.p_50 THEN 'medium'
		   ELSE 'low'
		   END AS spending_tier
FROM customer_revenue AS cr
CROSS JOIN percentile AS p
ORDER BY total_revenue DESC NULLS LAST;


-- ====================================================================================
-- SECTION 2: EMPLOYEE PERFORMANCE ANALYSIS
-- Description: Evaluating employee contribution to revenue, order volume, and
-- measuring tenure and age to identify experience-based patterns.
-- Tables Used: employees (e), orders (o), order_details (od)
-- Metrics:
-- 1: Total Orders Handled per Employee
-- 2: Total Revenue Generated per Employee
-- 3: Employee Age (calculated from birth date)
-- 4: Years of Service (calculated from hire date)
-- 5: Experience vs Sales Pattern
-- 6: Revenue Ranking using RANK()
-- ====================================================================================

-- ------------------------------------------------------------------------------------
-- Query 2: Employee orders, age, experience, revenue and rank (combined)
-- ------------------------------------------------------------------------------------

SELECT e.employee_id,
       CONCAT (e.first_name, ' ', e.last_name )                                                                                              AS employee_name,
	   EXTRACT (YEAR FROM AGE(MAX (order_date),  birth_date))                                                                                AS age,
	   EXTRACT (YEAR FROM AGE (MAX (order_date), hire_date))                                                                                 AS years_of_experience,
	   COUNT (o.order_id)                                                                                                                    AS total_orders_handled,
	   ROUND (SUM ((od.unit_price * od.quantity) - (od.unit_price * od.quantity * od.discount)) :: NUMERIC, 0 )                              AS total_revenue,
	   RANK () OVER (ORDER BY ROUND (SUM ((od.unit_price * od.quantity) - (od.unit_price * od.quantity * od.discount)) :: NUMERIC, 0 ) DESC) AS rank	   
FROM employees          AS e
LEFT JOIN orders        AS o
ON e.employee_id = o.employee_id
LEFT JOIN order_details AS od
ON o.order_id = od.order_id
GROUP BY e.employee_id,
         CONCAT (e.first_name, ' ', e.last_name )
ORDER BY total_revenue DESC;


-- ====================================================================================
-- SECTION 3: PRODUCT AND CATEGORY ANALYSIS
-- Description: Identifying top and bottom performing products by quantity and revenue,
-- and evaluating category dominance across the product catalogue.
-- Tables Used: products (p), categories (c), order_details (od)
-- Metrics:
-- 1: Top 10 Products by Quantity Sold
-- 2: Top 10 Products by Revenue
-- 3: Category Revenue Totals
-- 4: Average Order Value by Category
-- 5: Bottom 10 Underperforming Products by Revenue
-- 6: Product Revenue Rank within Each Category using RANK() PARTITION BY
-- ====================================================================================

-- ------------------------------------------------------------------------------------
-- Query 3a: Top 10 products by quantity sold and revenue
-- ------------------------------------------------------------------------------------

SELECT p.product_id,
       p.product_name,
	   SUM (od.quantity)                                                                                        AS total_quantity_ordered,
       ROUND (SUM ((od.unit_price * od.quantity) - (od.unit_price * od.quantity * od.discount)) :: NUMERIC, 0 ) AS total_revenue
FROM products           AS p
LEFT JOIN order_details AS od
ON p.product_id = od.product_id
GROUP BY p.product_id,
       p.product_name
ORDER BY total_revenue DESC
LIMIT 10;

-- ------------------------------------------------------------------------------------
-- Query 3b: Bottom 10 products by quantity sold and revenue
-- ------------------------------------------------------------------------------------

SELECT p.product_id,
       p.product_name,
	   SUM (od.quantity)                                                                                        AS total_quantity_ordered,
       ROUND (SUM ((od.unit_price * od.quantity) - (od.unit_price * od.quantity * od.discount)) :: NUMERIC, 0 ) AS total_revenue
FROM products           AS p
LEFT JOIN order_details AS od
ON p.product_id = od.product_id
GROUP BY p.product_id,
       p.product_name
ORDER BY total_revenue 
LIMIT 10;

-- ------------------------------------------------------------------------------------
-- Query 3c: Category revenue totals with product level ranking within each category
-- ------------------------------------------------------------------------------------

SELECT c.category_id,
       c.category_name,
	   p.product_name,
	   SUM (od.quantity)                                                                                                                     AS total_quantity_ordered,
       ROUND (SUM ((od.unit_price * od.quantity) - (od.unit_price * od.quantity * od.discount)) :: NUMERIC, 0 )                              AS total_revenue,
	   RANK () OVER (PARTITION BY category_name
	                 ORDER BY ROUND (SUM ((od.unit_price * od.quantity) - (od.unit_price * od.quantity * od.discount)) :: NUMERIC, 0 ) DESC) AS rank
FROM categories         AS c
LEFT JOIN products      AS p
ON c.category_id = p.category_id
LEFT JOIN order_details AS od
ON p.product_id = od.product_id
GROUP BY c.category_id,
         c.category_name,
		 p.product_name
ORDER BY c.category_name, total_revenue DESC;


-- ====================================================================================
-- SECTION 4: SUPPLIER ANALYSIS
-- Description: Identifying which suppliers contribute the most to the product
-- catalogue and revenue, and which countries they operate from.
-- Tables Used: suppliers (s), products (p), order_details (od)
-- Metrics:
-- 1: Number of Products Supplied per Supplier
-- 2: Revenue Generated per Supplier
-- 3: Top Supplier Countries by Revenue
-- 4: Underperforming Suppliers by Revenue
-- ====================================================================================

-- ------------------------------------------------------------------------------------
-- Query 4a: Total products supplied per supplier
-- ------------------------------------------------------------------------------------

SELECT s.supplier_id,
      s.company_name,
	  s.country,
	  COUNT (p.product_id) AS total_products_supplied
	 
FROM suppliers     AS s
LEFT JOIN products AS p
ON s.supplier_id = p.supplier_id
GROUP BY s.supplier_id,
         s.company_name,
		 s.country
ORDER BY total_products_supplied DESC;

-- ------------------------------------------------------------------------------------
-- Query 4b: Total revenue and country per supplier (top performers)
-- ------------------------------------------------------------------------------------

SELECT s.supplier_id,
       s.company_name,
	   s.country,
	   ROUND (SUM ((od.unit_price * od.quantity) - (od.unit_price * od.quantity * od.discount)) :: NUMERIC, 0 ) AS total_revenue
FROM suppliers          AS s
INNER JOIN products     AS p
ON s.supplier_id = p.supplier_id
LEFT JOIN order_details AS od
ON p.product_id = od.product_id
GROUP BY s.supplier_id,
       s.company_name,
	   s.country
ORDER BY total_revenue DESC;

-- ------------------------------------------------------------------------------------
-- Query 4c: Underperforming suppliers by revenue (bottom performers)
-- ------------------------------------------------------------------------------------

SELECT s.supplier_id,
       s.company_name,
	   s.country,
	   ROUND (SUM ((od.unit_price * od.quantity) - (od.unit_price * od.quantity * od.discount)) :: NUMERIC, 0 ) AS total_revenue
FROM suppliers          AS s
INNER JOIN products     AS p
ON s.supplier_id = p.supplier_id
LEFT JOIN order_details AS od
ON p.product_id = od.product_id
GROUP BY s.supplier_id,
       s.company_name,
	   s.country
ORDER BY total_revenue
LIMIT 5;


-- ====================================================================================
-- SECTION 5: SHIPPING AND DELIVERY PERFORMANCE
-- Description: Evaluating shipper efficiency through average delivery time, order
-- volume handled, and late shipment rates.
-- Tables Used: shippers (s), orders (o)
-- Metrics:
-- 1: Average Delivery Time per Shipper
-- 2: Fastest Shipper by Average Delivery Days
-- 3: Total Orders Handled per Shipper
-- 4: Late Shipments (shipped after required date)
-- 5: Slowest Delivery Countries
-- ====================================================================================

-- ------------------------------------------------------------------------------------
-- Query 5a: Shipper performance — orders, delivery time and late shipments (combined)
-- ------------------------------------------------------------------------------------

SELECT s.shipper_id,
       s.company_name,
	   COUNT (o.order_id)                                             AS total_orders,
	   EXTRACT ( DAYS FROM (AVG (AGE(o.shipped_date, o.order_date)))) AS average_delivery_days,
	   COUNT (CASE WHEN
	                   o.shipped_date < o.required_date THEN 1
					   END)                                           AS early_delivery,
	   COUNT (CASE WHEN
	                   o.shipped_date >= o.required_date THEN 1
					   END)                                           AS late_delivery
FROM shippers     AS s
INNER JOIN orders AS o
ON s.shipper_id = o.ship_via
GROUP BY s.shipper_id,
         s.company_name
ORDER BY total_orders DESC;

-- ------------------------------------------------------------------------------------
-- Query 5b: Country performance — orders, delivery time and late shipments (combined)
-- ------------------------------------------------------------------------------------

SELECT o.ship_country,
	   COUNT (o.order_id)                                             AS total_orders,
	   EXTRACT ( DAYS FROM (AVG (AGE(o.shipped_date, o.order_date)))) AS average_delivery_days,
	   COUNT (CASE WHEN
	                   o.shipped_date < o.required_date THEN 1
					   END)                                           AS early_delivery,
	   COUNT (CASE WHEN
	                   o.shipped_date >= o.required_date THEN 1
					   END)                                           AS late_delivery
FROM shippers     AS s
INNER JOIN orders AS o
ON s.shipper_id = o.ship_via
GROUP BY o.ship_country
ORDER BY average_delivery_days DESC, total_orders DESC;


-- ====================================================================================
-- SECTION 6: ADVANCED INSIGHTS AND REVENUE TRENDS
-- Description: Deep analysis using CTEs, window functions, and subqueries to uncover
-- revenue trends over time, customer segments, and multi-metric rankings.
-- Tables Used: orders (o), order_details (od), customers (c), employees (e)
-- Metrics:
-- 1: Monthly Revenue Trend Across All Years
-- 2: Month with Consistently Highest Average Sales
-- 3: Customers Above and Below Average Revenue (subquery)
-- 4: Customer Spending Tiers using NTILE(4)
-- 5: Running Total of Revenue Over Time
-- 6: Country with Highest Revenue and Fastest Delivery (multi-CTE)
-- ====================================================================================

-- ------------------------------------------------------------------------------------
-- Query 6a: Monthly revenue trend across all years
-- ------------------------------------------------------------------------------------

SELECT DATE_PART ('Month',  o.order_date)                                                                       AS month_num,
       TO_CHAR (o.order_date, 'Month')                                                                          AS month_name,
       ROUND (SUM ((od.unit_price * od.quantity) - (od.unit_price * od.quantity * od.discount)) :: NUMERIC, 0 ) AS total_revenue
FROM orders              AS o
INNER JOIN order_details AS od
ON o.order_id = od.order_id
GROUP BY DATE_PART ('Month',  o.order_date),
       TO_CHAR (o.order_date, 'Month')
ORDER BY month_num;

-- ------------------------------------------------------------------------------------
-- Query 6b: Which month consistently generates the highest average sales
-- ------------------------------------------------------------------------------------

SELECT DATE_PART ('Year',  o.order_date)                                                                        AS year,
       DATE_PART ('Month',  o.order_date)                                                                       AS month_num,
       TO_CHAR (o.order_date, 'Month YYYY')                                                                     AS month_name,
       ROUND (SUM ((od.unit_price * od.quantity) - (od.unit_price * od.quantity * od.discount)) :: NUMERIC, 0 ) AS total_revenue
FROM orders              AS o
INNER JOIN order_details AS od
ON o.order_id = od.order_id
GROUP BY DATE_PART ('Year',  o.order_date) ,
        DATE_PART ('Month',  o.order_date),
       TO_CHAR (o.order_date, 'Month YYYY')
ORDER BY year, month_num;

-- ------------------------------------------------------------------------------------
-- Query 6c: Customers above and below company average revenue (subquery)
-- ------------------------------------------------------------------------------------

SELECT c.customer_id,
       c.contact_name,
	   ROUND (SUM ((od.unit_price * od.quantity) - (od.unit_price * od.quantity * od.discount)) :: NUMERIC, 0 ) AS total_revenue,
	   AVG ((od.unit_price * od.quantity) - (od.unit_price * od.quantity * od.discount))                        AS average_revenue,
	   CASE WHEN ROUND (SUM ((od.unit_price * od.quantity) - (od.unit_price * od.quantity * od.discount)) :: NUMERIC, 0 ) > 
	            (SELECT AVG ((od.unit_price * od.quantity) - (od.unit_price * od.quantity * od.discount))
	          FROM customers AS c
              LEFT JOIN orders AS o
              ON c.customer_id = o.customer_id
              LEFT JOIN order_details AS od
               ON o.order_id = od.order_id) THEN 'above_average'
			  ELSE 'below_average'
			  END                                                                                               AS performance
FROM customers AS c
LEFT JOIN orders AS o
ON c.customer_id = o.customer_id
LEFT JOIN order_details AS od
ON o.order_id = od.order_id
WHERE od.order_id IS NOT NULL
GROUP BY c.customer_id,
         c.contact_name
ORDER BY total_revenue DESC;

-- ------------------------------------------------------------------------------------
-- Query 6d: Customer spending tiers using NTILE(4)
-- ------------------------------------------------------------------------------------

SELECT c.customer_id,
       c.contact_name,
	   ROUND (SUM ((od.unit_price * od.quantity) - (od.unit_price * od.quantity * od.discount)) :: NUMERIC, 0 )                                 AS total_revenue,
	   NTILE (4) OVER (ORDER BY ROUND (SUM ((od.unit_price * od.quantity) - (od.unit_price * od.quantity * od.discount)) :: NUMERIC, 0 ) DESC ) AS percentile,
	   CASE NTILE (4) OVER (ORDER BY ROUND (SUM ((od.unit_price * od.quantity) - (od.unit_price * od.quantity * od.discount)) :: NUMERIC, 0 ) DESC )
	        WHEN 1 THEN 'tier 1'
			WHEN 2 THEN 'tier 2'
			WHEN 3 THEN 'tier 3'
			WHEN 4 THEN 'tier 4'
			END                                                                                                                                  AS tier_segment
FROM customers          AS c
LEFT JOIN orders        AS o
ON c.customer_id = o.customer_id
LEFT JOIN order_details AS od
ON o.order_id = od.order_id
WHERE od.order_id IS NOT NULL
GROUP BY c.customer_id,
         c.contact_name
ORDER BY total_revenue DESC;

-- ------------------------------------------------------------------------------------
-- Query 6e: Running total of revenue over time using CTE and window function
-- ------------------------------------------------------------------------------------

WITH monthly_revenue AS ( 
					     SELECT 
						       EXTRACT (YEAR FROM order_date)                                                                           AS year,
							   EXTRACT (MONTH FROM order_date)                                                                          AS monthly_num,
							   TO_CHAR (order_date , 'Month YYYY')                                                                      AS month_name,
							   ROUND (SUM ((od.unit_price * od.quantity) - (od.unit_price * od.quantity * od.discount)) :: NUMERIC , 0) AS monthly_revenue
						 FROM orders AS o
					     INNER JOIN order_details AS od
					     ON o.order_id = od.order_id
						 GROUP BY EXTRACT (YEAR FROM order_date),
							   EXTRACT (MONTH FROM order_date) ,
							   TO_CHAR (order_date , 'Month YYYY'))

SELECT year,
       monthly_num,
	   month_name,
	  SUM (monthly_revenue)  OVER (ORDER BY year, monthly_num) AS running_total
FROM monthly_revenue;

-- ------------------------------------------------------------------------------------
-- Query 6f: Country with highest revenue AND fastest delivery using dual CTE
-- ------------------------------------------------------------------------------------

WITH highest_revenue AS (
					     SELECT c.country,
						        ROUND (SUM ((od.unit_price * od.quantity) - (od.unit_price * od.quantity * od.discount)) :: NUMERIC, 0 ) AS total_revenue
					     FROM customers          AS c
					     LEFT JOIN orders        AS o
					     ON c.customer_id = o.customer_id
					     LEFT JOIN order_details AS od
					     ON o.order_id = od.order_id	   
					     GROUP BY c.country
					     ),

fastest_delivery AS (
 SELECT c.country,
        EXTRACT (DAY FROM (AVG (AGE(shipped_date, order_date)))) average_delivery_day
 FROM orders          AS o
 INNER JOIN customers AS c
 ON o.customer_id = c.customer_id
 GROUP BY country
                  )
				  
 SELECT hr.country,
        hr.total_revenue,
		fd.average_delivery_day
		
 FROM highest_revenue        AS hr
 INNER JOIN fastest_delivery AS fd
 ON hr.country = fd.country
 ORDER BY  hr.total_revenue DESC, fd.average_delivery_day;
 

  -- ####################################################################################