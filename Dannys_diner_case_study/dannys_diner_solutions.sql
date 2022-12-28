SELECT
  	product_id,
    product_name,
    price
FROM dannys_diner.menu
ORDER BY price DESC
LIMIT 5;

-- What is the total amount each customer spent at the restaurant?
select s.customer_id, sum(p.price) as total_price
from dannys_diner.sales s
inner join dannys_diner.menu p on 
p.product_id= s.product_id
group by 1;

-- 2. How many days has each customer visited the restaurant?

select customer_id, count(distinct order_date) as visited_times
from dannys_diner.sales
group by 1;

-- 3. What was the first item from the menu purchased by each customer?

select customer_id, product
from(
select s.customer_id, dense_rank() over(partition by s.customer_id order by s.order_date) as rnk, p.product_name as product 
from dannys_diner.sales s 
inner join dannys_diner.menu p on 
s.product_id= p.product_id) sub 
where rnk =1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

with cte as(select product_id, count(*) as cnt
from dannys_diner.sales
group by 1)
  
select m.product_name, cte.cnt as total_count from cte
inner join dannys_diner.menu m on 
m.product_id= cte.product_id
where cnt in (select max(cnt) from cte);

-- 5. Which item was the most popular for each customer?

with cte as(select customer_id, product_id, count(*) as cnt
from dannys_diner.sales
group by 1,2)

select cte.customer_id, m.product_name 
from cte 
inner join dannys_diner.menu m on 
m.product_id = cte.product_id
where cte.cnt in (select max(cnt) from cte b where b.customer_id = cte.customer_id);

-- 6. Which item was purchased first by the customer after they became a member?

with cte as(select m.customer_id, s.product_id, dense_rank() over (partition by m.customer_id order by s.order_date) as rnk
from dannys_diner.members m 
inner join dannys_diner.sales s on 
 m.customer_id = s.customer_id 
 and m.join_date <= s.order_date)
 
 select cte.customer_id, m.product_name
 from cte inner join 
 dannys_diner.menu m on 
 m.product_id = cte.product_id 
 where rnk= 1;
 
 -- 7. Which item was purchased just before the customer became a member?

with cte as(select m.customer_id, s.product_id, dense_rank() over (partition by m.customer_id order by s.order_date desc) as rnk
from dannys_diner.members m 
inner join dannys_diner.sales s on 
 m.customer_id = s.customer_id 
 and m.join_date > s.order_date)
 
 select cte.customer_id, m.product_name
 from cte inner join 
 dannys_diner.menu m on 
 m.product_id = cte.product_id 
 where rnk= 1;
 
 -- 8. What is the total items and amount spent for each member before they became a member?
 
with cte as(select m.customer_id, s.product_id, dense_rank() over (partition by m.customer_id order by s.order_date desc) as rnk
from dannys_diner.members m 
inner join dannys_diner.sales s on 
 m.customer_id = s.customer_id 
 and m.join_date > s.order_date)
 
 select cte.customer_id, sum(m.price) as money_spent
 from cte 
 inner join 
 dannys_diner.menu m on 
 m.product_id = cte.product_id
 group by 1;
 
 
 -- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
 
 select customer_id, sum(points) as points
 from(
 select s.customer_id,m.product_name, 
 case when m.product_name= 'sushi' then 2*10* sum(m.price) else 10* sum(m.price) end as points
 from dannys_diner.sales s 
 inner join dannys_diner.menu m on 
 m.product_id = s.product_id
 group by 1,2) sub group by 1;
 
 -- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
 
 with cte as(select s.customer_id,s.order_date,m2.join_date,m.product_name, sum(case when m.product_name= 'sushi' then 20*m.price else 10*m.price end) as points 
 
 from dannys_diner.sales s 
 inner join dannys_diner.menu m on 
 m.product_id= s.product_id 
 inner join dannys_diner.members m2 on 
 m2.customer_id = s.customer_id 
 group by 1,2,3,4)
 
 select customer_id, sum(case when product_name != 'sushi' and 
                         order_date >= join_date and 
                         order_date- join_date <=6 then 2* points else points end) as points
                         from cte 
                         where extract('month' from order_date) =01
                         group by 1;
                         
-- joining tables 

select s.customer_id, s.order_date,m2.product_name, m2.price,
case when s.order_date< m.join_date or m.join_date is NULL then 'N' else 'Y' end as member
from dannys_diner.sales s 
left join dannys_diner.members m on 
m.customer_id = s.customer_id 
inner join dannys_diner.menu m2 on m2.product_id= s.product_id;
-- Ranking 

with cte as (select s.customer_id, s.order_date,m.join_date,m2.product_name, m2.price,
case when s.order_date< m.join_date or m.join_date is NULL then 'N' else 'Y' end as member
from dannys_diner.sales s 
left join dannys_diner.members m on 
m.customer_id = s.customer_id 
inner join dannys_diner.menu m2 on m2.product_id= s.product_id)


select customer_id, order_date, product_name, 
price, member,
 rank() over( partition by customer_id order by order_date)  as ranking
from cte
where  member = 'Y' and order_date>= join_date 
union all 
select customer_id, order_date, product_name,price, member, NULL as ranking
from cte 
where member= 'N' and (order_date < join_date or join_date IS NULL)
order by 1,2,3;
