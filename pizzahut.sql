-- Highlights:
-- #13 identifies the top 3 pizzas by revenues in each category.
-- #12 Cumulative Revenue Generated Over Time
-- #9 Average pizza ordered every day.
-- #7 Busiest hours of the day.
-- #5 Top 5 Most ordered pizzas, their size, quantity, and revenue.

CREATE DATABASE pizzahut;
USE pizzahut;

CREATE TABLE orders(
	order_id INT NOT NULL,
    order_date DATE NOT NULL,
    order_time TIME NOT NULL,
    PRIMARY KEY(order_id)
);

CREATE TABLE order_details(
	order_details_id INT NOT NULL,
    order_id INT NOT NULL,
    pizza_id TEXT NOT NULL,
    quantity INT NOT NULL,
    PRIMARY KEY(order_details_id)
);

LOAD DATA INFILE 'D:/MySQL Learning/Data Analyst SQL/pizza_sales/order_details.csv' 
INTO TABLE order_details
FIELDS TERMINATED BY ','
IGNORE 1 Lines; 

SELECT * FROM pizzas;
SELECT * FROM pizza_types;
SELECT * FROM order_details;
SELECT * FROM orders;


-- 1. Total numbers of orders placed

SELECT COUNT(order_id) AS total_orders FROM orders;


-- 2. Total revenue from pizza sales

SELECT 
    ROUND(SUM(order_details.quantity * pizzas.price),
            2) AS total_sales
FROM
    order_details
        JOIN
    pizzas ON order_details.pizza_id = pizzas.pizza_id;
    
    
--  3. Highest priced pizza. The Name of highest priced pizza.

SELECT 
    t.name, p.price
FROM
    pizza_types t
        JOIN
    pizzas p ON t.pizza_type_id = p.pizza_type_id
HAVING MAX(price);


-- (4. extra - most common pizza size ordered)

-- find size in pizzas
-- find quantity in order_details
-- find name in pizza_types

SELECT 
    pizza_types.name,
    p.size,
    o.quantity,
    SUM(o.quantity) AS total_quantity_ordered
FROM
    pizza_types
        JOIN
    pizzas p ON pizza_types.pizza_type_id = p.pizza_type_id
        JOIN
    order_details o ON o.pizza_id = p.pizza_id
GROUP BY pizza_types.name
ORDER BY total_quantity_ordered DESC;

-- Notes about above - Incorrect script
-- It finds total quantity of every pizza type ordered.
-- However, we need only the most common *size* ordered

-- Correct statement ahead:

-- 4. most common pizza size ordered

SELECT 
    p.size, COUNT(o.order_details_id) AS order_count
FROM
    pizzas p
        JOIN
    order_details o ON p.pizza_id = o.pizza_id
GROUP BY p.size
ORDER BY order_count DESC;

-- The above gives the aggregate value of pizza sizes. 
-- The previous script gave aggregate value for the type of pizza.


-- 5. List of top 5 most ordered pizza, their types, and quantities.

SELECT 
    pizza_types.name,
    SUM(o.quantity) AS total_quantity_ordered
FROM
    pizza_types
JOIN pizzas p
	ON pizza_types.pizza_type_id = p.pizza_type_id
JOIN order_details o
	ON o.pizza_id = p.pizza_id
GROUP BY pizza_types.name
ORDER BY total_quantity_ordered DESC
LIMIT 5;


-- Intermediate
-- 6. Find total quantity of each pizza category ordered

SELECT 
    p.category, SUM(o.quantity) AS TotalQuantity
FROM
    pizza_types p
JOIN pizzas 
	ON p.pizza_type_id = pizzas.pizza_type_id
JOIN order_details o
	ON o.pizza_id = pizzas.pizza_id
GROUP BY p.category
ORDER BY TotalQuantity DESC;


-- 7. Distribution of orders by hour of the day. 
-- Helps determine at what time of the day there are most pizza orders.

SELECT 
    HOUR(order_time) AS DayHour, COUNT(order_ID) AS OrderCount
FROM
    orders
GROUP BY HOUR(order_time)
ORDER BY DayHour;


-- 8. Category wise distribution of pizzas.
-- Helps answer the number of pizzas in each category.

SELECT 
    category, COUNT(category) AS PizzasInCategory
FROM
    pizza_types
GROUP BY category
ORDER BY PizzasInCategory DESC;


-- 9. Group the orders by date and 
-- calculate average numver of pizzas ordered per day

SELECT 
    ROUND(AVG(quantity),0) AS OrdersPerDay
FROM
    (SELECT 
        o.order_date, SUM(d.quantity) AS quantity
    FROM
        orders o
    JOIN order_details d ON o.order_id = d.order_id
    GROUP BY o.order_date) AS order_quantity;


-- 10. Top 3 most ordered pizza types based on revenue.

SELECT 
    t.name, SUM(p.price * d.quantity) AS revenue
FROM
    pizza_types t
        JOIN
    pizzas p ON t.pizza_type_id = p.pizza_type_id
        JOIN
    order_details d ON d.pizza_id = p.pizza_id
GROUP BY t.name
ORDER BY revenue DESC
LIMIT 3;


-- 11. Percentage contribution of pizza category in total revenue

SELECT 
    t.category,
    ROUND(100 * SUM(p.price * d.quantity) / (SELECT 
                    SUM(order_details.quantity * pizzas.price) AS total_sales
                FROM
                    order_details
				JOIN pizzas 
				ON order_details.pizza_id = pizzas.pizza_id),2) AS revenue
FROM pizza_types t
JOIN pizzas p 
ON t.pizza_type_id = p.pizza_type_id
JOIN order_details d
ON d.pizza_id = p.pizza_id
GROUP BY t.category
ORDER BY revenue DESC;


-- 12. Cumulative Revenue generated over time.

SELECT order_date, revenue, ROUND(SUM(revenue) OVER (ORDER BY order_date),2) AS CumulativeRevenue
FROM
(SELECT 
	o.order_date, ROUND(SUM(d.quantity * p.price),2) AS revenue 
FROM orders o
JOIN order_details d
ON o.order_id = d.order_id
JOIN pizzas p
ON p.pizza_id = d.pizza_id
GROUP BY o.order_date) as sales;


-- 13. Top 3 most ordered pizza types based on revenue for each pizza category.

SELECT name, category, ROUND(TotalPizzaRevenue,2) AS PizzaRevenue 
FROM
(SELECT name, category, TotalPizzaRevenue, rank() OVER (PARTITION BY category ORDER BY TotalPizzaRevenue DESC) as rnk
FROM
	(SELECT 
		t.name, t.category, SUM(d.quantity * p.price) AS TotalPizzaRevenue
	FROM pizza_types t
		JOIN pizzas p
			ON p.pizza_type_id = t.pizza_type_id
		JOIN order_details d
			ON d.pizza_id = p.pizza_id
		GROUP BY t.category, t.name
		ORDER BY t.category, TotalPizzaRevenue DESC) as RevenueTable) AS RANKTABLE
WHERE rnk <=3
ORDER BY rnk DESC;