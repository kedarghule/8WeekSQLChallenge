/* --------------------
   Case Study Questions
   --------------------*/
USE sql_8_week_cs1; 
-- 1. What is the total amount each customer spent at the restaurant?
SELECT c.customer_id, SUM(p.price) FROM sales c INNER JOIN menu p on c.product_id=p.product_id GROUP BY c.customer_id;

-- 2. How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT order_date) FROM sales GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?
WITH CTE AS (
  SELECT c.customer_id, p.product_name, ROW_NUMBER()OVER(PARTITION BY c.customer_id ORDER BY c.customer_id) AS row_number FROM sales c INNER JOIN menu p ON c.product_id=p.product_id 
  )
SELECT customer_id, product_name FROM CTE where row_number=1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT p.product_id, m.product_name, COUNT(p.product_id) FROM sales p INNER JOIN menu m ON p.product_id=m.product_id GROUP BY p.product_id, m.product_name ORDER BY COUNT(p.product_id) DESC LIMIT 1;

-- 5. Which item was the most popular for each customer?
With rank as
(
Select S.customer_ID ,
       M.product_name, 
       Count(S.product_id) as Count,
       Dense_rank()  Over (Partition by S.Customer_ID order by Count(S.product_id) DESC ) as R
From menu m
join sales s
On m.product_id = s.product_id
group by S.customer_id,S.product_id,M.product_name
)
Select Customer_id,Product_name,Count
From rank
where R=1;


-- 6. Which item was purchased first by the customer after they became a member?
WITH CTE AS (
  SELECT s.customer_id, s.order_date, s.product_id, ROW_NUMBER()OVER(PARTITION BY s.customer_id ORDER BY s.customer_id) AS row_number FROM sales s INNER JOIN members m ON s.customer_id=m.customer_id WHERE s.order_date>=m.join_date ORDER BY s.order_date
  )
SELECT CTE.customer_id, m.product_name FROM CTE INNER JOIN menu m ON CTE.product_id=m.product_id WHERE row_number=1;

-- 7. Which item was purchased just before the customer became a member?
WITH CTE AS (
  SELECT s.customer_id, s.order_date, s.product_id, ROW_NUMBER()OVER(PARTITION BY s.customer_id ORDER BY s.customer_id) AS rn FROM sales s INNER JOIN members m ON s.customer_id=m.customer_id WHERE s.order_date<m.join_date ORDER BY s.order_date DESC
  )
SELECT DISTINCT CTE.*, t2.product_name FROM CTE INNER JOIN (SELECT CTE.*, MAX(rn) OVER(PARTITION BY CTE.customer_id) AS rn_max FROM CTE) t1 ON CTE.rn=t1.rn_max AND CTE.customer_id=t1.customer_id INNER JOIN menu t2 ON t2.product_id=CTE.product_id;

-- 8. What is the total items and amount spent for each member before they became a member?
WITH CTE AS (
  SELECT s.customer_id, m2.price FROM sales s INNER JOIN members m ON s.customer_id=m.customer_id INNER JOIN menu m2 ON s.product_id=m2.product_id WHERE s.order_date<m.join_date ORDER BY s.order_date DESC
  )
SELECT customer_id, SUM(price) FROM CTE GROUP BY customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
With Points as
(
Select *, Case When product_id = 1 THEN price*20
               Else price*10
	       End as Points
From menu
)
Select S.customer_id, Sum(P.points) as Points
From sales S
Join Points p
On p.product_id = S.product_id
Group by S.customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH cust_points AS(
SELECT s.customer_id
    , s.order_date
    , mm.join_date
    , mm.join_date + INTERVAL '6 days' AS end_promo
    , s.product_id
    , m.price
    , CASE 
        WHEN s.product_id = 1
            THEN m.price * 20 
        WHEN s.product_id != 1 AND 
        (s.order_date BETWEEN mm.join_date AND mm.join_date + INTERVAL '6 days')
            THEN (m.price * 20)
        ELSE m.price * 10
        END AS points
FROM sales s
JOIN members mm USING(customer_id)
JOIN menu m USING(product_id)
WHERE 
    s.order_date <= '2021-01-31'
  )
SELECT customer_id
    , SUM(points)  AS total
FROM cust_points
GROUP BY customer_id;


-- Example Query:
/*SELECT
  	product_id,
    product_name,
    price
FROM menu
ORDER BY price DESC
LIMIT 5;*/