CREATE SCHEMA pizza_runner;
SET search_path = pizza_runner;

DROP TABLE IF EXISTS runners;
CREATE TABLE runners (
  "runner_id" INTEGER,
  "registration_date" DATE
);
INSERT INTO runners
  ("runner_id", "registration_date")
VALUES
  (1, '2021-01-01'),
  (2, '2021-01-03'),
  (3, '2021-01-08'),
  (4, '2021-01-15');


DROP TABLE IF EXISTS customer_orders;
CREATE TABLE customer_orders (
  "order_id" INTEGER,
  "customer_id" INTEGER,
  "pizza_id" INTEGER,
  "exclusions" VARCHAR(4),
  "extras" VARCHAR(4),
  "order_time" TIMESTAMP
);

INSERT INTO customer_orders
  ("order_id", "customer_id", "pizza_id", "exclusions", "extras", "order_time")
VALUES
  ('1', '101', '1', '', '', '2020-01-01 18:05:02'),
  ('2', '101', '1', '', '', '2020-01-01 19:00:52'),
  ('3', '102', '1', '', '', '2020-01-02 23:51:23'),
  ('3', '102', '2', '', NULL, '2020-01-02 23:51:23'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '2', '4', '', '2020-01-04 13:23:46'),
  ('5', '104', '1', 'null', '1', '2020-01-08 21:00:29'),
  ('6', '101', '2', 'null', 'null', '2020-01-08 21:03:13'),
  ('7', '105', '2', 'null', '1', '2020-01-08 21:20:29'),
  ('8', '102', '1', 'null', 'null', '2020-01-09 23:54:33'),
  ('9', '103', '1', '4', '1, 5', '2020-01-10 11:22:59'),
  ('10', '104', '1', 'null', 'null', '2020-01-11 18:34:49'),
  ('10', '104', '1', '2, 6', '1, 4', '2020-01-11 18:34:49');


DROP TABLE IF EXISTS runner_orders;
CREATE TABLE runner_orders (
  "order_id" INTEGER,
  "runner_id" INTEGER,
  "pickup_time" VARCHAR(19),
  "distance" VARCHAR(7),
  "duration" VARCHAR(10),
  "cancellation" VARCHAR(23)
);

INSERT INTO runner_orders
  ("order_id", "runner_id", "pickup_time", "distance", "duration", "cancellation")
VALUES
  ('1', '1', '2020-01-01 18:15:34', '20km', '32 minutes', ''),
  ('2', '1', '2020-01-01 19:10:54', '20km', '27 minutes', ''),
  ('3', '1', '2020-01-03 00:12:37', '13.4km', '20 mins', NULL),
  ('4', '2', '2020-01-04 13:53:03', '23.4', '40', NULL),
  ('5', '3', '2020-01-08 21:10:57', '10', '15', NULL),
  ('6', '3', 'null', 'null', 'null', 'Restaurant Cancellation'),
  ('7', '2', '2020-01-08 21:30:45', '25km', '25mins', 'null'),
  ('8', '2', '2020-01-10 00:15:02', '23.4 km', '15 minute', 'null'),
  ('9', '2', 'null', 'null', 'null', 'Customer Cancellation'),
  ('10', '1', '2020-01-11 18:50:20', '10km', '10minutes', 'null');


DROP TABLE IF EXISTS pizza_names;
CREATE TABLE pizza_names (
  "pizza_id" INTEGER,
  "pizza_name" TEXT
);
INSERT INTO pizza_names
  ("pizza_id", "pizza_name")
VALUES
  (1, 'Meatlovers'),
  (2, 'Vegetarian');


DROP TABLE IF EXISTS pizza_recipes;
CREATE TABLE pizza_recipes (
  "pizza_id" INTEGER,
  "toppings" TEXT
);
INSERT INTO pizza_recipes
  ("pizza_id", "toppings")
VALUES
  (1, '1, 2, 3, 4, 5, 6, 8, 10'),
  (2, '4, 6, 7, 9, 11, 12');


DROP TABLE IF EXISTS pizza_toppings;
CREATE TABLE pizza_toppings (
  "topping_id" INTEGER,
  "topping_name" TEXT
);
INSERT INTO pizza_toppings
  ("topping_id", "topping_name")
VALUES
  (1, 'Bacon'),
  (2, 'BBQ Sauce'),
  (3, 'Beef'),
  (4, 'Cheese'),
  (5, 'Chicken'),
  (6, 'Mushrooms'),
  (7, 'Onions'),
  (8, 'Pepperoni'),
  (9, 'Peppers'),
  (10, 'Salami'),
  (11, 'Tomatoes'),
  (12, 'Tomato Sauce');
  
--Cleaning the customer_orders table
--checking the data type os columns in customers_order table:
SELECT
  table_name,
  column_name,
  data_type
FROM information_schema.columns
WHERE table_name = 'customer_orders';

--rectifying null values
CREATE TEMP TABLE updated_customer_orders AS (
  SELECT
    order_id,
    customer_id,
    pizza_id,
    CASE 
      WHEN exclusions IS NULL 
        OR exclusions LIKE 'null' THEN ''
      ELSE exclusions 
    END AS exclusions,
    CASE 
      WHEN extras IS NULL
        OR extras LIKE 'null' THEN ''
      ELSE extras 
    END AS extras,
    order_time
  FROM pizza_runner.customer_orders
);
SELECT * FROM updated_customer_orders;

--dealing with runner_orders table
--checking for schemas
SELECT
  table_name,
  column_name,
  data_type
FROM information_schema.columns
WHERE table_name = 'runner_orders';

--updating runner_orders
DROP TABLE IF EXISTS updated_runner_orders;
CREATE TEMP TABLE updated_runner_orders AS (
  SELECT
    order_id,
    runner_id,
    CASE WHEN pickup_time LIKE 'null' THEN null ELSE pickup_time END::timestamp AS pickup_time,
    NULLIF(regexp_replace(distance, '[^0-9.]','','g'), '')::numeric AS distance,
    NULLIF(regexp_replace(duration, '[^0-9.]','','g'), '')::numeric AS duration,
    CASE WHEN cancellation IN ('null', 'NaN', '') THEN null ELSE cancellation END AS cancellation
  FROM pizza_runner.runner_orders);


SELECT * FROM updated_runner_orders;

		--A. Pizza Metrics
--1.How many pizzas were ordered?
SELECT COUNT(*) AS pizza_count
FROM updated_customer_orders;

--2.How many unique customer orders were made?
SELECT COUNT(DISTINCT(order_id)) AS unique_orders
FROM updated_customer_orders;

--3.How many successful orders were delivered by each runner?
SELECT
  runner_id,
  COUNT(order_id) AS successful_orders
FROM updated_runner_orders
WHERE cancellation IS NULL
OR cancellation NOT IN ('Restaurant Cancellation', 'Customer Cancellation')
GROUP BY runner_id;

--4.How many of each type of pizza was delivered?
SELECT
  pn.pizza_name,
  COUNT(co.*) AS pizza_type_count
FROM updated_customer_orders AS co
JOIN pizza_runner.runner_orders AS ro
   ON co.order_id = ro.order_id
JOIN pizza_runner.pizza_names AS pn
   ON co.pizza_id = pn.pizza_id
WHERE cancellation IS NULL
OR cancellation NOT IN ('Restaurant Cancellation', 'Customer Cancellation')
GROUP BY pn.pizza_name
ORDER BY pn.pizza_name;

--5.How many Vegetarian and Meatlovers were ordered by each customer?
SELECT
  customer_id,
  SUM(CASE WHEN pizza_id = 1 THEN 1 ELSE 0 END) AS meat_lovers,
  SUM(CASE WHEN pizza_id = 2 THEN 1 ELSE 0 END) AS vegetarian
FROM updated_customer_orders
GROUP BY customer_id;

--6.What was the maximum number of pizzas delivered in a single order?
SELECT MAX(pizza_count) AS max_count
FROM (
  SELECT
    co.order_id,
    COUNT(co.pizza_id) AS pizza_count
  FROM updated_customer_orders AS co
  INNER JOIN updated_runner_orders AS ro
    ON co.order_id = ro.order_id
  WHERE 
    ro.cancellation IS NULL
    OR ro.cancellation NOT IN ('Restaurant Cancellation', 'Customer Cancellation')
  GROUP BY co.order_id) AS mycount;

--7.For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT 
  co.customer_id,
  SUM (CASE WHEN co.exclusions <> '' OR co.extras <> '' THEN 1 ELSE 0 END) AS changes,
  SUM (CASE WHEN co.exclusions = '' OR co.extras = '' THEN 1 ELSE 0 END) AS no_change
FROM updated_customer_orders AS co
INNER JOIN updated_runner_orders AS ro
  ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL
  OR ro.cancellation NOT IN ('Restaurant Cancellation', 'Customer Cancellation')
GROUP BY co.customer_id
ORDER BY co.customer_id;

--8.How many pizzas were delivered that had both exclusions and extras?
SELECT 
  SUM (CASE WHEN co.exclusions <> '' AND co.extras <> '' THEN 1 ELSE 0 END) AS pizza_count
FROM updated_customer_orders AS co
INNER JOIN updated_runner_orders AS ro
  ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL
  OR ro.cancellation NOT IN ('Restaurant Cancellation', 'Customer Cancellation');
  
--9.What was the total volume of pizzas ordered for each hour of the day?
SELECT
  DATE_PART('hour', order_time::TIMESTAMP) AS hour_of_day,
  COUNT(*) AS pizza_count
FROM updated_customer_orders
GROUP BY hour_of_day;

--10.What was the volume of orders for each day of the week?
SELECT
  TO_CHAR(order_time, 'Day') AS day_of_week,
  COUNT(*) AS pizza_count
FROM updated_customer_orders
GROUP BY 
  day_of_week, 
  DATE_PART('dow', order_time)
ORDER BY day_of_week;

--B. Runner and Customer Experience

--1.How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
WITH runner_signups AS (
  SELECT
    runner_id,
    registration_date,
    registration_date - ((registration_date - '2021-01-01') % 7)  AS start_of_week
  FROM runners
)
SELECT
  start_of_week,
  COUNT(runner_id) AS signups
FROM runner_signups
GROUP BY start_of_week
ORDER BY start_of_week;

--2.What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
WITH runner_pickups AS (
  SELECT
    ro.runner_id,
    ro.order_id,
    co.order_time,
    ro.pickup_time,
    (pickup_time - order_time) AS time_to_pickup
  FROM updated_runner_orders AS ro
  INNER JOIN updated_customer_orders AS co
    ON ro.order_id = co.order_id
)
SELECT 
  runner_id,
  date_part('minutes', AVG(time_to_pickup)) AS avg_arrival_minutes
FROM runner_pickups
GROUP BY runner_id
ORDER BY runner_id;

--3.Is there any relationship between the number of pizzas and how long the order takes to prepare?
WITH order_count AS (
  SELECT
    order_id,
    order_time,
    COUNT(pizza_id) AS pizzas_order_count
  FROM updated_customer_orders
  GROUP BY order_id, order_time
), 
prepare_time AS (
  SELECT
    ro.order_id,
    co.order_time,
    ro.pickup_time,
    co.pizzas_order_count,
    (pickup_time - order_time) AS time_to_pickup
  FROM updated_runner_orders AS ro
  JOIN order_count AS co
    ON ro.order_id = co.order_id
  WHERE pickup_time IS NOT NULL
)

SELECT
  pizzas_order_count,
  AVG(time_to_pickup) AS avg_time
FROM prepare_time
GROUP BY pizzas_order_count
ORDER BY pizzas_order_count;

--4.What was the average distance travelled for each customer?
SELECT co.customer_id, ROUND(AVG(ro.distance), 2) AS avg_distance
FROM updated_customer_orders AS co
JOIN updated_runner_orders AS ro
	ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL
  OR ro.cancellation NOT IN ('Restaurant Cancellation', 'Customer Cancellation')
GROUP BY co.customer_id;  

--5.What was the difference between the longest and shortest delivery times for all orders?
SELECT
  MAX(duration) - MIN(duration) AS difference
FROM updated_runner_orders;

--6.What was the average speed for each runner for each delivery and do you notice any trend for these values?
WITH order_count AS (
  SELECT
    order_id,
    order_time,
    COUNT(pizza_id) AS pizzas_count
  FROM updated_customer_orders
  GROUP BY 
    order_id, 
    order_time
)
  SELECT
    ro.order_id,
    ro.runner_id,
    co.pizzas_count,
    ro.distance,
    ro.duration,
    ROUND(60 * ro.distance / ro.duration, 2) AS speed
  FROM updated_runner_orders AS ro
  INNER JOIN order_count AS co
    ON ro.order_id = co.order_id
  WHERE pickup_time IS NOT NULL
  ORDER BY speed DESC;
/* Conclusion: Orders shown in decreasing order of average speed:
The fastest order: 1 pizza
The slowest order: 3 pizzas,
therefore, there is no clear trend that more pizzas slow down the delivery speed of an order. 
*/
  
--7.What is the successful delivery percentage for each runner?
SELECT
  runner_id,
  COUNT(pickup_time) as delivered,
  COUNT(order_id) AS total,
  ROUND(100 * COUNT(pickup_time) / COUNT(order_id)) AS delivery_percent
FROM updated_runner_orders
GROUP BY runner_id
ORDER BY runner_id;

		--C. Ingredient Optimisation

--1.What are the standard ingredients for each pizza?
WITH ingredient AS (
	SELECT pizza_id, TO_NUMBER(regexp_split_to_table(toppings, ', '), '99') AS toppings
	FROM pizza_recipes
)
SELECT pn.pizza_id, pn.pizza_name, pt.topping_name AS ingredients
FROM pizza_names AS pn
JOIN ingredient AS ing
	ON pn.pizza_id = ing.pizza_id
JOIN pizza_toppings AS pt
	ON ing.toppings = pt.topping_id
ORDER BY pn.pizza_id;
	
--2.What was the most commonly added extra?
WITH extras AS (
	SELECT CAST(regexp_split_to_table(extras, ', ')AS INTEGER) AS extras
	FROM updated_customer_orders AS co
	WHERE co.extras <> ''
)
SELECT DISTINCT(extras), pt.topping_name AS e_name, COUNT(extras) AS topping_count
FROM extras AS ext
JOIN pizza_toppings AS pt
	ON ext.extras = pt.topping_id
GROUP BY extras, e_name
ORDER BY topping_count DESC;

--3.What was the most common exclusion?
WITH exclusions AS (
	SELECT CAST(regexp_split_to_table(exclusions, ', ')AS INTEGER) AS exclusions
	FROM updated_customer_orders AS co
	WHERE co.exclusions <> ''
)
SELECT DISTINCT(exclusions), pt.topping_name AS e_name, COUNT(exclusions) AS exclusion_count
FROM exclusions AS exl
JOIN pizza_toppings AS pt
	ON exl.exclusions = pt.topping_id
GROUP BY exclusions, e_name
ORDER BY exclusion_count DESC;

--4.Generate an order item for each record in the customers_orders table in the format of one of the following:
        --Meat Lovers
		SELECT order_id, customer_id
		FROM updated_customer_orders
		WHERE pizza_id = 1;
        --Meat Lovers - Exclude Beef
		WITH exclusion AS (
				SELECT co.order_id, co.customer_id, CAST(regexp_split_to_table(exclusions, ', ')AS INTEGER) AS exclusions
				FROM updated_customer_orders AS co
				WHERE co.exclusions <> ''
		)		
		SELECT COUNT(exc.order_id)
		FROM updated_customer_orders AS uco, exclusion AS exc
		WHERE uco.pizza_id = 1 AND exc.exclusions = (SELECT topping_id
											   	FROM pizza_toppings
											    WHERE topping_name = 'Beef');
		
        --Meat Lovers - Extra Bacon
		WITH extra AS (
				SELECT co.order_id, co.customer_id, CAST(regexp_split_to_table(extras, ', ')AS INTEGER) AS extras
				FROM updated_customer_orders AS co
				WHERE co.extras <> ''
		)		
		SELECT COUNT(ext.order_id)
		FROM updated_customer_orders AS uco, extra AS ext
		WHERE uco.pizza_id = 1 AND ext.extras = (SELECT topping_id
											   	FROM pizza_toppings
											    WHERE topping_name = 'Bacon');

        --Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
		WITH exclusion AS (
				SELECT co.order_id, co.customer_id, CAST(regexp_split_to_table(exclusions, ', ')AS INTEGER) AS exclusions
				FROM updated_customer_orders AS co
				WHERE co.exclusions <> ''
		), extra AS (
				SELECT co.order_id, co.customer_id, CAST(regexp_split_to_table(extras, ', ')AS INTEGER) AS extras
				FROM updated_customer_orders AS co
				WHERE co.extras <> ''
		)
		SELECT COUNT(ext.order_id)
		FROM updated_customer_orders AS uco, extra AS ext, exclusion AS exc
		WHERE uco.pizza_id = 1 AND ext.extras IN (SELECT topping_id
											   	FROM pizza_toppings
											    WHERE topping_name = 'Mushroom' AND topping_name = 'Peppers') AND exc.exclusions IN (
																												SELECT topping_id
											   																	FROM pizza_toppings
											    																WHERE topping_name = 'Bacon' AND topping_name = 'Cheese');
		
/*5.Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
        For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"*/
		--use string_agg() and concat() 
		--take note of extras and excludes. 
		--postfix 2x with extras
WITH ingredient AS (
		SELECT pizza_id, TO_NUMBER(regexp_split_to_table(toppings, ', '), '99') AS toppings
		FROM pizza_recipes
	), exclusion AS (
		SELECT co.order_id, CAST(regexp_split_to_table(exclusions, ', ')AS INTEGER) AS exclusions
		FROM updated_customer_orders AS co
		WHERE co.exclusions <> ''
	), extra AS (
		SELECT co.order_id, CAST(regexp_split_to_table(extras, ', ')AS INTEGER) AS extras
		FROM updated_customer_orders AS co
		WHERE co.extras <> ''
	)
SELECT co.order_id, 
	   CASE WHEN co.order_id NOT IN exc.order_id AND co.order_id NOT IN ext.order_id
	   			THEN CONCAT()
FROM updated_customer_orders AS co, ingredients AS ing, exclusion AS exc, extra AS ext



--6.What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?


WITH ingredients AS ( 
	SELECT co.order_id, pr.pizza_id, 
		   regexp_split_to_table(toppings, ',') AS ing_id 
	FROM pizza_recipes pr 
	JOIN customer_orders co
		ON pr.pizza_id = co.pizza_id 
	), count_extras AS ( 
	SELECT order_id, regexp_split_to_table(extras, ',') AS extra_topp_id 
	FROM customer_orders 
	where extras is not null and extras <> '' and extras <> 'null' 
	), ingredients_name AS ( 
		SELECT co.order_id, ing.pizza_id, pt.topping_name, pt.topping_id 
		FROM pizza_toppings pt 
		JOIN ingredients ing 
			ON pt.topping_id = ing.ing_id :: int 
		JOIN customer_orders co 
			ON co.order_id = ing.order_id 
		GROUP BY co.order_id, ing.pizza_id, pt.topping_name ,pt.topping_id 
	), ingredients_name_with_extras AS ( 
		select ing.order_id,ing.pizza_id, 
			case when ce.extra_topp_id is not null then '2x '|| ing.topping_name 
				else ing.topping_name 
			end as topping_name_with_extras 
		from ingredients_name ing 
		left join count_extras ce 
			on ing.order_id :: int = ce.order_id :: int and ing.topping_id = ce.extra_topp_id :: int 
	) 
	/*select * 
	from ingredients_name 
	order by order_id 
	select * 
	from ingredients_name_with_extras 
	order by order_id*/ 
	SELECT inn.order_id, pn.pizza_name, 
			string_agg(inn.topping_name_with_extras, ', ' ORDER BY inn.topping_name_with_extras) AS topping_name 
	FROM pizza_names pn 
	JOIN ingredients_name_with_extras inn 
		ON pn.pizza_id = inn.pizza_id 
	GROUP BY pn.pizza_name, inn.order_id;
