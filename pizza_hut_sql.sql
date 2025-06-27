CREATE TABLE order_details(
order_details_id INT,
order_id INT,
pizza_id VARCHAR(50),
quantity INT
)

CREATE TABLE orders (
order_id INT,
date DATE,
time TIME
)

CREATE TABLE pizza_types (
    pizza_type_id TEXT PRIMARY KEY,
    name TEXT,
    category TEXT,
    ingredients TEXT
) 

CREATE TABLE pizzas(	
pizza_id VARCHAR(50),
pizza_type_id VARCHAR(50),
size VARCHAR(5),
price FLOAT
)


-- Q1 Retrieve the total number of orders placed.

SELECT COUNT(order_id) AS total_order_place
FROM orders 

-- Q2 Calculate the total revenue generated from pizza sales.

SELECT ROUND(SUM(pizza_sales):: NUMERIC , 2) AS total_revenue 
FROM (
SELECT o.order_id, o.pizza_id, p.price, o.quantity, (o.quantity * p.price) AS Pizza_sales 
FROM order_details AS o
JOIN pizzas AS p
ON o.pizza_id = p.pizza_id ) AS x

-- Q3 Identify the highest-priced pizza.

SELECT * FROM pizzas
WHERE price = (SELECT MAX(price)
                 FROM pizzas
)
-- Q4 Identify the most common pizza size ordered.

SELECT COUNT( DISTINCT order_details_id), size
FROM (
   SELECT o.order_details_id, o.order_id, o.pizza_id, p.pizza_type_id, p.size
   FROM order_details AS o
   JOIN pizzas AS p
   ON o.pizza_id = p.pizza_id) AS x
GROUP BY size

-- Q5 List the top 5 most ordered pizza types along with their quantities.

SELECT SUM(quantity) AS Most_ordered_pizza ,name
FROM (
	SELECT o.order_details_id, o.quantity, o.order_id, o.pizza_id, p.pizza_type_id, p.name, p.category, pi.price
	FROM order_details AS o
	JOIN pizzas AS pi
	ON o.pizza_id = pi.pizza_id
	JOIN pizza_types AS p
	ON p.pizza_type_id = pi.pizza_type_id
    ) AS Quantity_table
GROUP BY name
ORDER BY Most_ordered_pizza DESC
LIMIT 5


-- Intermediate:

-- Q6 Join the necessary tables to find the total quantity of each pizza category ordered.


SELECT SUM(quantity) AS total_quantity_sold, category
FROM (
	SELECT o.order_details_id, o.order_id, o.pizza_id, o.quantity, p.price, p.size, pt.pizza_type_id, pt.name, pt.category
	FROM order_details AS o
	JOIN pizzas AS p
	ON o.pizza_id = p.pizza_id
	JOIN pizza_types AS pt
	ON pt.pizza_type_id = p.pizza_type_id
	) AS finder
GROUP BY category
ORDER BY total_quantity_sold DESC

-- Q7 Determine the distribution of orders by hour of the day.

SELECT COUNT(order_id) AS pizza_sold, EXTRACT(HOUR FROM time) AS per_hour
FROM orders 
GROUP BY per_hour
ORDER BY per_hour ASC

-- Q8 Join relevant tables to find the category-wise distribution of pizzas.

SELECT pt.category, COUNT(p.pizza_id) AS total_pizzas
FROM pizzas AS p
JOIN pizza_types AS pt
ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.category
ORDER BY total_pizzas DESC;

-- Q9 Group the orders by date and calculate the average number of pizzas ordered per day.

SELECT ROUND(AVG(total_pizzas)::NUMERIC, 0) AS avg_pizzas_per_day
FROM (
    SELECT o.date, SUM(od.quantity) AS total_pizzas
    FROM orders o
    JOIN order_details od
	ON o.order_id = od.order_id
    GROUP BY o.date
) AS daily_totals;

-- Q10 Determine the top 3 most ordered pizza types based on revenue.

SELECT ROUND(SUM(total_amount) :: NUMERIC, 2) AS total_revenue, name
FROM (
	SELECT o.order_details_id, o.order_id, o.pizza_id , p.size, p.price, o.quantity, 
	(p.price * o.quantity) AS total_amount, pt.name, pt.category
	FROM order_details AS o
	JOIN pizzas AS p
	ON o.pizza_id = p.pizza_id
	JOIN pizza_types AS pt
	ON p.pizza_type_id = pt.pizza_type_id )
	GROUP BY name 
	ORDER BY total_revenue DESC
	LIMIT 3 

-- Advanced:

-- Q11 Calculate the percentage contribution of each pizza type to total revenue.

SELECT 
  pt.category, 
  ROUND((
    SUM(o.quantity * p.price) / 
    (SELECT SUM(o.quantity * p.price) 
     FROM order_details o
     JOIN pizzas p ON p.pizza_id = o.pizza_id)
  )::NUMERIC * 100, 2) AS revenue_percentage
FROM pizza_types pt
JOIN pizzas p ON pt.pizza_type_id = p.pizza_type_id
JOIN order_details o ON o.pizza_id = p.pizza_id
GROUP BY pt.category
ORDER BY revenue_percentage DESC;

-- Q12 Analyze the cumulative revenue generated over time.

SELECT *,
SUM(revenue) OVER(ORDER BY date ) AS total_revenue
FROM (
SELECT o.date, ROUND(SUM(od.quantity * p.price):: NUMERIC, 2 ) AS revenue 
FROM orders AS o
JOIN order_details AS od
ON o.order_id = od.order_id
JOIN pizzas AS p
ON p.pizza_id = od.pizza_id
GROUP BY date ) AS x


-- Q13 Determine the top 3 most ordered pizza types based on revenue for each pizza category.

SELECT * 
FROM (
SELECT pt.name, pt.category, ROUND(SUM(o.quantity * p.price)::NUMERIC, 2) AS revenue,
RANK() OVER(PARTITION BY category ORDER BY ROUND(SUM(o.quantity * p.price)::NUMERIC, 2) DESC) AS Ranking
FROM pizza_types AS pt
JOIN pizzas AS p
ON pt.pizza_type_id = p.pizza_type_id
JOIN order_details AS o
ON o.pizza_id = p.pizza_id 
GROUP BY pt.name, pt.category ) AS x
WHERE ranking <= 3



SELECT name, category, revenue
FROM (
    SELECT 
        pt.name, 
        pt.category, 
        SUM(o.quantity * p.price) AS revenue,
        RANK() OVER (PARTITION BY pt.category ORDER BY SUM(o.quantity * p.price) DESC) AS rnk
    FROM pizza_types pt
    JOIN pizzas p ON pt.pizza_type_id = p.pizza_type_id
    JOIN order_details o ON o.pizza_id = p.pizza_id
    GROUP BY pt.name, pt.category
) AS ranked
WHERE rnk <= 3
ORDER BY category, revenue DESC;

