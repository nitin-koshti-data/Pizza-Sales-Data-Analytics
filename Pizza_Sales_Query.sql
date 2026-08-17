SELECT * FROM pizza_sales;

ALTER TABLE pizza_sales 
ALTER COLUMN order_date TYPE date USING order_date::date;

ALTER TABLE pizza_sales 
ALTER COLUMN week TYPE date USING week::date;

ALTER TABLE pizza_sales 
DROP COLUMN day_name;

-- Find total revenue,total order,avg order value,total pizza sold
SELECT SUM(total_price) AS total_revenue,
		COUNT(DISTINCT order_id) AS total_order,
		SUM(quantity) AS total_pizza_sold,
		ROUND((SUM(total_price)/COUNT(DISTINCT order_id))::numeric, 2) AS avg_order_value
FROM pizza_sales;

-- Daily trend for total order
SELECT order_date,COUNT(DISTINCT order_id) AS total_order
FROM pizza_sales
GROUP BY order_date ORDER BY order_date;

--monthly trend for revenue
SELECT month,ROUND((SUM(total_price))::numeric,2) AS total_revenue
FROM pizza_sales
GROUP BY month ORDER BY total_revenue DESC;

--Sales By pizza Category
SELECT pizza_category,ROUND((SUM(total_price))::numeric,2) AS total_revenue
FROM pizza_sales
GROUP BY pizza_category ORDER BY total_revenue DESC;

--avg number of pizza per order
SELECT order_id,ROUND((AVG(quantity))::NUMERIC,2) AS avg_pizza_sold
FROM pizza_sales
GROUP BY order_id ORDER BY avg_pizza_sold DESC ;

--total pizza per order
SELECT order_id,SUM(quantity) AS total_pizza_sold
FROM pizza_sales
GROUP BY order_id ORDER BY total_pizza_sold DESC ;

--Sales By pizza Size
SELECT pizza_size,SUM(quantity) AS total_pizza_sold,
		ROUND((SUM(total_price))::numeric,2) AS total_revenue
FROM pizza_sales
GROUP BY pizza_size ORDER BY total_revenue DESC;

--top 5 best selling pizza by Quantity
SELECT pizza_name,SUM(quantity) AS total_pizza_sold
FROM pizza_sales
GROUP BY pizza_name ORDER BY total_pizza_sold DESC LIMIT 5;

--bottom 5 worst selling pizza by Quantity
SELECT pizza_name,SUM(quantity) AS total_pizza_sold
FROM pizza_sales
GROUP BY pizza_name ORDER BY total_pizza_sold ASC LIMIT 5;

--TOP 5 Pizzas By Revenue
SELECT pizza_name,ROUND((SUM(total_price))::numeric,2) AS total_revenue
FROM pizza_sales
GROUP BY pizza_name ORDER BY total_revenue DESC LIMIT 5;

--Order By Day_of_Week
SELECT day_of_week,SUM(quantity) AS total_pizza_sold
FROM pizza_sales
GROUP BY day_of_week ORDER BY total_pizza_sold DESC ;

--Order By Hour of Day
SELECT hours_of_day,SUM(quantity) AS total_pizza_sold
FROM pizza_sales
GROUP BY hours_of_day ORDER BY hours_of_day ;

--weekly Order,total revenue,avg order value,total pizza sold
SELECT week,
		COUNT(DISTINCT order_id) AS total_order,
		SUM(quantity) AS total_pizza_sold,
		Round((SUM(total_price))::numeric,2) AS total_revenue,
		ROUND((SUM(total_price)/COUNT(DISTINCT order_id))::numeric, 2)
		AS avg_order_value
FROM pizza_sales
GROUP BY week ORDER BY week ;

--percentage of contribution of each category to total revenue
SELECT pizza_category,ROUND((SUM(total_price))::numeric,2) AS total_revenue,
	   ROUND((SUM(total_price)*100/(SELECT SUM(total_price) FROM pizza_sales))::numeric,2)
		AS percentage_of_Contribution
FROM pizza_sales
GROUP BY pizza_category ORDER BY percentage_of_Contribution DESC;

--which day_of_week has the highest number of order
SELECT day_of_week,SUM(quantity) AS total_pizza_sold
FROM pizza_sales
GROUP BY day_of_week ORDER BY total_pizza_sold DESC LIMIT 1;

--What is the busiest hours of the day for order
SELECT hours_of_day,SUM(quantity) AS total_pizza_sold
FROM pizza_sales
GROUP BY hours_of_day ORDER BY total_pizza_sold DESC LIMIT 1;

--Is there a difference in order patternbetween weekdays or weekends?
SELECT
	CASE
		WHEN EXTRACT(DOW FROM order_date) IN (0,6) THEN 'weekends'
		ELSE 'weekdays'
	END AS day_type,
	COUNT(DISTINCT order_id) AS total_order,
		SUM(quantity) AS total_pizza_sold,
		Round((SUM(total_price))::numeric,2) AS total_revenue,
		ROUND((SUM(total_price)/COUNT(DISTINCT order_id))::numeric, 2) AS avg_order_value
FROM pizza_sales
GROUP BY day_type ORDER BY total_order DESC  ;

--month over month revenue growth
WITH monthly_revenue AS (
SELECT EXTRACT(MONTH FROM order_date) AS month,
		Round(SUM(total_price)::numeric,2) AS total_revenue
FROM pizza_sales
GROUP BY EXTRACT(MONTH FROM order_date)
)
SELECT month,total_revenue,
		COALESCE(LAG(total_revenue) OVER(ORDER BY month),0) AS prev_month_sales,
		COALESCE(ROUND((total_revenue-LAG(total_revenue) OVER(ORDER BY month))
		/LAG(total_revenue) OVER(ORDER BY month)*100,2),0)
FROM monthly_revenue
ORDER BY month;

--find top 3 best-selling pizza within each category
SELECT pizza_category,pizza_name,total_revenue,RANK FROM(
SELECT pizza_category,pizza_name,ROUND((SUM(total_price))::numeric,2) AS total_revenue,
	RANK() OVER(PARTITION BY pizza_category ORDER BY ROUND((SUM(total_price))::numeric,2)
	DESC) AS RANK
FROM pizza_sales
GROUP BY pizza_category,pizza_name)rn
WHERE RANK <=3 ORDER BY pizza_category, RANK;

--Calculate running total of revenue By date
WITH daily_revenue AS (
	SELECT order_date,ROUND((SUM(total_price))::numeric,2) AS total_revenue
	FROM pizza_sales
	GROUP BY order_date
)
SELECT order_date,total_revenue,
		SUM(total_revenue) over(ORDER BY order_date) AS CUMULATIVE_SALE
FROM daily_revenue
ORDER BY order_date