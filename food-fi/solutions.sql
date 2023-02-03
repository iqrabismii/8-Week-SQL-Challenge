SELECT * FROM foodie_fi.plans;

-- Part A: Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey? 

select  p.plan_name, count(*) as total_customers
from foodie_fi.subscriptions s 
inner join foodie_fi.plans p 
on s.plan_id = p.plan_id 
group by 1
order by 2 desc;

/*  From the query, we can see that most customers were engaged in basic monthly plan. */



		--Part B
        
-- 1.How many customers has Foodie-Fi ever had?
select  count(distinct s.customer_id) as total_customers
from foodie_fi.subscriptions s 
inner join foodie_fi.plans p 
on s.plan_id = p.plan_id;


-- 2.What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value.

select  extract('month' from s.start_date) as month, count(*)  as trial_customers
from foodie_fi.subscriptions s 
inner join foodie_fi.plans p 
on s.plan_id = p.plan_id 
where p.plan_name = 'trial'
group by 1
order by 1;

-- 3.What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name?

select  p.plan_name, min(s.start_date) as mn_date, count(*) as eventcount
from foodie_fi.subscriptions s 
inner join foodie_fi.plans p 
on s.plan_id = p.plan_id 
where extract('year' from s.start_date) >= 2020
group by 1
order by 2 desc;

-- 4.What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
select  count(case when p.plan_name= 'churn' then
 1 end) totalcustomer,  round(count(case when p.plan_name= 'churn' then
 1 end)*100/count(distinct s.customer_id),2) as churned  
 from foodie_fi.subscriptions s 
left join foodie_fi.plans p 
on s.plan_id = p.plan_id ;





-- 5.How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
with cte as(select customer_id, start_date from foodie_fi.subscriptions where plan_id =0)
            
select count(customer_id) as churnedcount, 
count(customer_id)*100/(select count(*) from cte) as perc_churned
from foodie_fi.subscriptions s
where s.plan_id = 4
and customer_id in (select customer_id from cte)
and customer_id not in (select customer_id from foodie_fi.subscriptions where plan_id in (1,2,3));




-- 6. What is the number and percentage of customer plans after their initial free trial?

select p.plan_name, count(s.customer_id) as totalcountbyplan, round(count(s.customer_id)*1.0/ 
(select count(s.customer_id) from foodie_fi.subscriptions s
inner join foodie_fi.plans p on 
s.plan_id = p.plan_id where p.plan_name= 'trial'),2) as totalperctbyplan
from foodie_fi.subscriptions s
inner join foodie_fi.plans p on 
s.plan_id = p.plan_id
where s.customer_id in (select customer_id from foodie_fi.subscriptions where plan_id = 0) and p.plan_name != 'trial'
group by 1;




-- 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

select p.plan_name, count(s.customer_id) as totalcountbyplan, 
round(count(s.customer_id)*1.0/(select count(*) from foodie_fi.subscriptions s
inner join foodie_fi.plans p on 
s.plan_id = p.plan_id
where s.start_date <= '2020-12-31'),2) as perct
from foodie_fi.subscriptions s
inner join foodie_fi.plans p on 
s.plan_id = p.plan_id
where s.start_date <= '2020-12-31'
group by 1;



-- 8. How many customers have upgraded to an annual plan in 2020?

select count(s.customer_id)
from foodie_fi.subscriptions s
inner join foodie_fi.plans p on 
s.plan_id = p.plan_id
where extract('year' from s.start_date) = 2020
and p.plan_name = 'pro annual';



-- 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
with cte as (select s1.customer_id, min(s1.start_date) as start_date
             from foodie_fi.subscriptions s1 group by 1)
             
select sum(s2.start_date- cte.start_date)*1.0/ count(cte.customer_id) 
average_upgrade
from cte
inner join foodie_fi.subscriptions s2
on cte.customer_id = s2.customer_id 
and cte.start_date < s2.start_date  and
s2.plan_id = 3;



-- 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
WITH trial_plan AS 
  (SELECT 
    customer_id, 
    start_date AS trial_date
  FROM foodie_fi.subscriptions
  WHERE plan_id = 0
  ),
  annual_plan AS
  (SELECT 
    customer_id, 
    start_date AS annual_date
  FROM foodie_fi.subscriptions
  WHERE plan_id = 3
  ),
  bins AS 
  (SELECT 
    WIDTH_BUCKET(ap.annual_date - tp.trial_date, 0, 360, 12) AS avg_days_to_upgrade
    FROM trial_plan tp
    JOIN annual_plan ap
        ON tp.customer_id = ap.customer_id)
  
SELECT 
  ((avg_days_to_upgrade - 1)*30 || ' - ' || (avg_days_to_upgrade)*30) || ' days' AS breakdown, 
  COUNT(*) AS customers
FROM bins
GROUP BY avg_days_to_upgrade
ORDER BY avg_days_to_upgrade;





-- 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

with cte as (select s1.customer_id , s1.start_date
             from foodie_fi.subscriptions s1 where s1.plan_id= 2 )
             
select count(cte.customer_id) as downgraded
from  foodie_fi.subscriptions s2
inner join cte on cte.customer_id = s2.customer_id
and cte.start_date <= s2.start_date and
s2.plan_id = 1




