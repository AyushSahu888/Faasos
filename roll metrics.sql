use faasos;
-- A roll metrics

 /* 1. How many rolls were ordered ? */
 select count(*) from customer_orders;
 
 # How many unique customer orders were made ?
 select   count(distinct customer_id) from customer_orders;
 
 -- How many successful order were delivered by each driver ?
 select driver_id,count(distinct order_id) no_of_successful_order from driver_order where cancellation not in ('Cancellation','Customer Cancellation')
  group by driver_id;
  
  -- 4. How many of each type of roll was ordered delivered ?
select roll_id,count(roll_id) as no_of_each_roll from customer_orders group by roll_id;  

-- 5. How many of each type of roll was  delivered ?
select roll_id,count(roll_id)  delivered_roll from customer_orders where order_id in 

(SELECT 
    order_id
FROM
    (SELECT 
        *,
            CASE
                WHEN cancellation IN ('Cancellation' , 'Customer Cancellation') THEN 'c'
                ELSE 'nc'
            END AS order_cancel_details
    FROM
        driver_order)a where  order_cancel_details = 'nc' )  group by roll_id;
        
-- 6. How many veg and non-veg rolls ordered by each customer ?
select a.*,b.roll_name from  (select customer_id,roll_id,count(roll_id) from customer_orders 
 group by customer_id,roll_id
 order by customer_id)a join rolls b on a.roll_id=b.roll_id;       
        
 -- 7. What was the maximum number of rolls delivered in a single order ?
select * from 
( select *,rank() over(order by cnt desc ) rnk from  
(select order_id,count(roll_id) cnt  from  
(select * from customer_orders where order_id in

 (SELECT 
    order_id
FROM
    (SELECT 
        *,
            CASE
                WHEN cancellation IN ('Cancellation' , 'Customer Cancellation') THEN 'c'
                ELSE 'nc'
            END AS order_cancel_details
    FROM
        driver_order)a where  order_cancel_details = 'nc'))b
        group by order_id)c)d where rnk = 1 ;      
        
 -- 8. For each customer, how many delivered rolls had at least 1 change and how many had no change ?  
 with temp_customer_orders (order_id ,customer_id ,roll_id ,not_include_items ,extra_items_included ,order_date ) as 
 ( select order_id ,customer_id ,roll_id, case when not_include_items is null or  not_include_items = ' ' then '0' else not_include_items end as new_not_include_items,
 case when extra_items_included is null or  extra_items_included = ' ' or extra_items_included ='NaN' then '0' else  extra_items_included  end as new_extra_items_included,
 order_date from customer_orders),

 temp_driver_order (order_id ,driver_id ,pickup_time ,distance ,duration ,new_cancellation ) as
  ( select order_id ,driver_id ,pickup_time ,distance ,duration ,
  case when  cancellation IN ('Cancellation' , 'Customer Cancellation') then 0 else 1 end as new_cancellation 
  from driver_order)
 select customer_id,change_or_no_change,count(order_id) at_least_1_cahnge from  
  
  (select *,case when not_include_items = 0 and extra_items_included = 0 then 'no change' else 'change' end  change_or_no_change  from temp_customer_orders where order_id in(
  select order_id from temp_driver_order where new_cancellation != 0))a
  group by customer_id,change_or_no_change;
  
-- 9. How many rolls delivered that had both exclusions and extras ?
 with temp_customer_orders (order_id ,customer_id ,roll_id ,not_include_items ,extra_items_included ,order_date ) as 
 ( select order_id ,customer_id ,roll_id, case when not_include_items is null or  not_include_items = ' ' then '0' else not_include_items end as new_not_include_items,
 case when extra_items_included is null or  extra_items_included = ' ' or extra_items_included ='NaN' then '0' else  extra_items_included  end as new_extra_items_included,
 order_date from customer_orders),

 temp_driver_order (order_id ,driver_id ,pickup_time ,distance ,duration ,new_cancellation ) as
  ( select order_id ,driver_id ,pickup_time ,distance ,duration ,
  case when  cancellation IN ('Cancellation' , 'Customer Cancellation') then 0 else 1 end as new_cancellation 
  from driver_order)
 
  select change_or_no_change,count(change_or_no_change) from 
  (select *,case when not_include_items != 0 and extra_items_included != 0 then 'both_included_excluded' else 'either 1 included or excluded' end  change_or_no_change  from temp_customer_orders where order_id in
  (
  select order_id from temp_driver_order where new_cancellation != 0))a
  group by change_or_no_change;
  
  -- 10. What was the the total number of rolls ordered for each hour of the day ? 
 select hours_bucket,count(hours_bucket) from  
  (select *,concat(hour(order_date),'-' ,hour(order_date)+1 ) hours_bucket from customer_orders)a
  group by hours_bucket
  order by hours_bucket;
  
  -- 11. What was the number of orders for each day of the week ?
  select dow,count(distinct order_id) from 
  (select *,dayname(order_date) dow from customer_orders)a
  group by dow;
        

  