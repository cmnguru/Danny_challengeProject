--- creating tables involved in the project 
Create Table Sales (
             Customer_ID varchar,
			 Order_Date date,
			 Product_ID Int )

Create Table Menu (
             Product_ID Int,
			 Product_Name varchar (50),
			 Price int )

Create Table Members (
             Customer_ID varchar,
			 Join_Date date )


--Inserting columns into the tables

Insert into Sales( Customer_ID,Order_Date,Product_ID)
Values ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');


Insert into Menu (Product_ID,Product_Name,Price)
Values  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');


  Insert Into Members (Customer_ID,Join_Date)
  Values  ('A', '2021-01-07'),
  ('B', '2021-01-09');

Check 
Select *
From DannyCHallenge..Menu

---Whats the total amount each customer spent at the restaurant
-Select Customer_ID,SUM(Price) as Total_amount
--From Sales Sa
--JOIN Menu  Me
   ON Sa.Product_ID = Me.Product_ID
Group by Customer_ID
- Customer A = 76,B = 74, C = 36.

-2. How many days has each customer visited the restaurant
Select Customer_ID,Count(Distinct(Order_Date)) as Visited_Days
From Sales 
-Group by Customer_ID
-Customer A = 4DAYS, B = 6DAYS, C = 2days

---3.What was the first item from the menu purchased by each customer?



WITH fpurchased  AS 
(
    SELECT customer_id, Order_Date, Product_name,
    DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY Order_date) AS Rank_num
    FROM Sales sa
    JOIN Menu me ON sa.Product_ID = me.Product_ID
)

select customer_id, Product_name
From fpurchased
where Rank_num =1
Group by customer_id, Product_name

--the first item to be purchsed is A = curry and sushi, B = curry, c = ramen  

----4..What is the most purchased item on the menu and how many times was it purchased by all customers?
Select Top 1 COUNT(sa.Product_ID) as mpurchased,product_name
From Sales sa
    JOIN Menu me
	ON sa.Product_ID = me.Product_ID
Group by product_name
order by mpurchased Desc

- The most purchased is Ramen and purchased 8 times

--5-Which item was the most popular for each customer?

WITH Mpopular
AS (
Select  sa.Customer_ID,me.product_name,COUNT(sa.Product_ID) as mpurchased,
DENSE_RANK () OVER (PARTITION BY sa.Customer_ID  ORDER BY Count(sa.Customer_ID) DESC) As rank
From Sales sa
    JOIN Menu me
	ON sa.Product_ID = me.Product_ID
Group by sa.Customer_ID,me.Product_Name
)
Select Customer_ID, Product_Name,mpurchased
From Mpopular
Where rank =1;
----Customer A and C’s favourite item is ramen. 
---Customer B enjoys all items in the menu. He/she is a true foodie.


----6.Which item was purchased first by the customer after they became a member?

WITH Mpurchased  AS 
(
Select sa.Customer_ID,sa.Order_Date,mem.Join_Date,sa.Product_ID,
DENSE_RANK() Over (Partition by sa.Customer_ID
             order by sa.Order_Date) AS Rank
From Sales sa
JOIN Members mem 
    ON sa.Customer_ID = mem.Customer_ID
Where sa.Order_Date >= mem.Join_Date
)
--Select *
--From Mpurchased 


Select s.Customer_ID,s.Order_Date,me.Product_Name
From Mpurchased S
JOIN Menu me
ON S.Product_ID = me.Product_ID
Where Rank = 1;

---- A purchased curry, B purchased Sushi

---7-Which item was purchased just before the customer became a member?

WITH Priormembership  AS 
(
Select sa.Customer_ID,sa.Order_Date,mem.Join_Date,sa.Product_ID,
DENSE_RANK() Over (Partition by sa.Customer_ID
             order by sa.Order_Date DESC) AS Rank
From Sales sa
JOIN Members mem 
    ON sa.Customer_ID = mem.Customer_ID
Where sa.Order_Date < mem.Join_Date
)

Select P.Customer_ID,P.Order_Date,me.Product_Name
From Priormembership P
JOIN Menu me
ON P.Product_ID = me.Product_ID
Where Rank = 1;


--8.What is the total items and amount spent for each member before they became a member?
Select sa.Customer_ID,Count(DISTINCT sa.Product_ID) AS Total_items,Sum(me.Price) AS total_amt
From Sales sa
JOIN Menu me
    ON sa.Product_ID = me.Product_id
JOIN Members mem
     ON sa.Customer_ID = mem.Customer_ID
Where sa.Order_Date < mem.Join_Date
Group by sa.Customer_ID;

---A HAS 2 at $25 while B has 2 at $40



--9-If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

WITH Price_points AS
(
 Select*,
CASE
        When Product_ID = 1 then Price *20
		Else Price *10
		END as total_points
FROM Menu 
)

Select sa.Customer_ID,SUM (p.total_points) AS totalpoint
From Price_points p
JOIN Sales sa
ON p.product_id = sa.product_id
Group by sa.Customer_ID;
----Total points for Customer A, B and C are 860, 940 and 360.

----10..In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi 
 --how many points do customer A and B have at the end of January?

WITH dates_cte AS 
(
   SELECT *, 
      DATEADD(DAY, 6, Join_Date) AS valid_date, 
      EOMONTH('2021-01-31') AS last_date
   FROM members 
)-- Lets say 
 ---Day -X to Day 1 (customer becomes member (join_date), each $1 spent is 10 points and for sushi, each $1 spent is 20 points.
 -- Day 1 (join_date) to Day 7 (valid_date), each $1 spent for all items is 20 points.
 -- Day 8 to last day of Jan 2021 (last_date), each $1 spent is 10 points and sushi is 2x points.

SELECT d.customer_id, s.order_date, d.join_date, 
 d.valid_date, d.last_date, m.product_name, m.price,
 SUM(CASE
  WHEN m.product_name = 'sushi' THEN 2 * 10* m.price
  WHEN s.order_date BETWEEN d.join_date AND d.valid_date THEN 2 * 10*  m.price
  ELSE 10* m.price
  END) AS points
FROM dates_cte AS d
JOIN sales AS s
 ON d.customer_id = s.customer_id
JOIN menu AS m
 ON s.product_id = m.product_id
WHERE s.order_date < d.last_date
---GROUP BY d.customer_id, s.order_date, d.join_date, d.valid_date, d.last_date, m.product_name, m.price

---Customer A has 1,370points and Customer B has 820 points.

--join All The Things and group memebers into N AND Y
WITH summary_cte AS 
(
 SELECT s.customer_id, s.order_date, m.product_name, m.price,
  CASE
  WHEN mem.join_date > s.order_date THEN 'N'
  WHEN mem.join_date <= s.order_date THEN 'Y'
  ELSE 'N' END AS member
  FROM sales AS s
  Left JOIN menu AS m
  ON s.product_id = m.product_id
 Left JOIN members AS mem
  ON s.customer_id = mem.customer_id
)
Select *
From summary_cte; 

----Rank alll things but excludes customers who is not yet members and return as null
 
WITH summary_cte AS (
 SELECT s.customer_id, s.order_date, m.product_name, m.price,
  CASE
  WHEN mem.join_date > s.order_date THEN 'N'
  WHEN mem.join_date <= s.order_date THEN 'Y'
  ELSE 'N' END AS member
  FROM sales AS s
  Left JOIN menu AS m
  ON s.product_id = m.product_id
 Left JOIN members AS mem
  ON s.customer_id = mem.customer_id
)
Select *, CASE
 WHEN member = 'N' then NULL
 ELSE
  RANK () OVER(PARTITION BY customer_id, member
  ORDER BY order_date) END AS ranking
From summary_cte;