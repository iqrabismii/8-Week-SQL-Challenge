# 🥑 Case Study #3 - Foodie-Fi

## 🎞 Solution - B. Data Analysis Questions

### 1. How many customers has Foodie-Fi ever had?

To find the number of Foodie-Fi's unique customers, I use `DISTINCT` and wrap `COUNT` around it.

````sql
SELECT 
  COUNT(DISTINCT customer_id) AS unique_customer
FROM foodie_fi.subscriptions;
````

**Answer:**

<img width="159" alt="image" src="https://user-images.githubusercontent.com/81607668/129764903-bb0480aa-bf92-46f7-b0e1-f4d0f9e96ae1.png">

- Foodie-Fi has 1,000 unique customers.

### 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value



````sql
select  extract('month' from s.start_date) as month, count(*)  as trial_customers
from foodie_fi.subscriptions s 
inner join foodie_fi.plans p 
on s.plan_id = p.plan_id 
where p.plan_name = 'trial'
group by 1
order by 1;
````

**Answer:**


<img width="366" alt="image" src="https://user-images.githubusercontent.com/108056063/216725416-30223fdb-d315-4ff4-9947-f8ffb373f453.png">

- March has the highest number of trial plans, whereas February has the lowest number of trial plans.

### 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name.

Question is asking for the number of plans for start dates occurring on 1 Jan 2021 and after grouped by plan names.
- Filter plans with start_dates occurring on 2021–01–01 and after.
- Group and order results by plan.

_Note: Question calls for events occuring after 1 Jan 2021, however I ran the query for events in 2020 as well as I was curious with the year-on-year results._

````sql
select  p.plan_name, min(s.start_date) as mn_date, count(*) as eventcount
from foodie_fi.subscriptions s 
inner join foodie_fi.plans p 
on s.plan_id = p.plan_id 
where extract('year' from s.start_date) >= 2020
group by 1
order by 2 desc;
````

**Answer:**


<img width="592" alt="image" src="https://user-images.githubusercontent.com/108056063/216725278-0978b33d-36d9-4a2b-bb5f-96205b551896.png">



### 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?



````sql
select  count(case when p.plan_name= 'churn' then
 1 end) totalcustomer,  round(count(case when p.plan_name= 'churn' then
 1 end)*100/count(distinct s.customer_id),2) as churned  
 from foodie_fi.subscriptions s 
left join foodie_fi.plans p 
on s.plan_id = p.plan_id ;;
````

**Answer:**

<img width="368" alt="image" src="https://user-images.githubusercontent.com/81607668/129840630-adebba8c-9219-4816-bba6-ba8119f298d9.png">

- There are 307 customers who have churned, which is 30.7% of Foodie-Fi customer base.

### 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?


````sql
with cte as(select customer_id, start_date from foodie_fi.subscriptions where plan_id =0)
            
select count(customer_id) as churnedcount, 
count(customer_id)*100/(select count(*) from cte) as perc_churned
from foodie_fi.subscriptions s
where s.plan_id = 4
and customer_id in (select customer_id from cte)
and customer_id not in (select customer_id from foodie_fi.subscriptions where plan_id in (1,2,3));
````

**Answer:**

<img width="378" alt="image" src="https://user-images.githubusercontent.com/81607668/129834269-98ab360b-985a-4c25-9d42-c89b97ba6ba8.png">

- There are 92 customers who churned straight after the initial free trial which is at 9% of entire customer base.

### 6. What is the number and percentage of customer plans after their initial free trial?

Question is asking for number and percentage of customers who converted to becoming paid customer after the trial. 

**Steps:**
- Find customer's next plan which is located in the next row using `LEAD()`. Run the `next_plan_cte` separately to view the next plan results and understand how `LEAD()` works.
- Filter for `non-null next_plan`. Why? Because a next_plan with null values means that the customer has churned. 
- Filter for `plan_id = 0` as every customer has to start from the trial plan at 0.

````sql
select p.plan_name, count(s.customer_id) as totalcountbyplan, round(count(s.customer_id)*1.0/ 
(select count(s.customer_id) from foodie_fi.subscriptions s
inner join foodie_fi.plans p on 
s.plan_id = p.plan_id where p.plan_name= 'trial'),2) as totalperctbyplan
from foodie_fi.subscriptions s
inner join foodie_fi.plans p on 
s.plan_id = p.plan_id
where s.customer_id in (select customer_id from foodie_fi.subscriptions where plan_id = 0) and p.plan_name != 'trial'
group by 1;
````
**Answer:**


<img width="589" alt="image" src="https://user-images.githubusercontent.com/108056063/216725008-c48fb29d-517b-4832-8c95-ffc73d6abc39.png">


### 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

````sql
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
````

**Answer:**


<img width="448" alt="image" src="https://user-images.githubusercontent.com/108056063/216724929-5405deee-bdc8-4724-8554-1eb9dace59e3.png">

### 8. How many customers have upgraded to an annual plan in 2020?

````sql
select count(s.customer_id)
from foodie_fi.subscriptions s
inner join foodie_fi.plans p on 
s.plan_id = p.plan_id
where extract('year' from s.start_date) = 2020
and p.plan_name = 'pro annual';
````

**Answer:**

<img width="160" alt="image" src="https://user-images.githubusercontent.com/81607668/129848711-3b64442a-5724-4723-bea7-e4515a8687ec.png">

- 196 customers upgraded to an annual plan in 2020.

### 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?

````sql
with cte as (select s1.customer_id, min(s1.start_date) as start_date
             from foodie_fi.subscriptions s1 group by 1)
             
select sum(s2.start_date- cte.start_date)*1.0/ count(cte.customer_id) 
average_upgrade
from cte
inner join foodie_fi.subscriptions s2
on cte.customer_id = s2.customer_id 
and cte.start_date < s2.start_date  and
s2.plan_id = 3;
````


**Answer:**

<img width="182" alt="image" src="https://user-images.githubusercontent.com/108056063/216724803-5c2bf320-4ccf-4500-b63a-499bb092ea4f.png">

- On average, it takes 105 days for a customer to upragde to an annual plan from the day they join Foodie-Fi.

### 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)

````sql
-- Filter results to customers at trial plan = 0
WITH trial_plan AS 
(SELECT 
  customer_id, 
  start_date AS trial_date
FROM foodie_fi.subscriptions
WHERE plan_id = 0
),
-- Filter results to customers at pro annual plan = 3
annual_plan AS
(SELECT 
  customer_id, 
  start_date AS annual_date
FROM foodie_fi.subscriptions
WHERE plan_id = 3
),
-- Sort values above in buckets of 12 with range of 30 days each
bins AS 
(SELECT 
  WIDTH_BUCKET(ap.annual_date - tp.trial_date, 0, 360, 12) AS avg_days_to_upgrade
FROM trial_plan tp
JOIN annual_plan ap
  ON tp.customer_id = ap.customer_id)
  
SELECT 
  ((avg_days_to_upgrade - 1) * 30 || ' - ' || (avg_days_to_upgrade) * 30) || ' days' AS breakdown, 
  COUNT(*) AS customers
FROM bins
GROUP BY avg_days_to_upgrade
ORDER BY avg_days_to_upgrade;
````

**Answer:**

<img width="399" alt="image" src="https://user-images.githubusercontent.com/81607668/130019061-d2b54041-83ff-4a92-b30e-f519fb904d91.png">

### 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

````sql
with cte as (select s1.customer_id , s1.start_date
             from foodie_fi.subscriptions s1 where s1.plan_id= 2 )
             
select count(cte.customer_id) as downgraded
from  foodie_fi.subscriptions s2
inner join cte on cte.customer_id = s2.customer_id
and cte.start_date <= s2.start_date and
s2.plan_id = 1
````

**Answer:**

<img width="115" alt="image" src="https://user-images.githubusercontent.com/81607668/130021792-6c37301f-bdf8-4d57-bbfd-ca86fc759a70.png">

- No customer has downgrade from pro monthly to basic monthly in 2020.
