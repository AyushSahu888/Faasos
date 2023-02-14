use faasos;
-- Driver and Customer Experience

-- 1. What was the average time in minutes it took for each driver to arrive at the faasos HQ to pickup the order?
select driver_id,sum(diff),count(order_id) avg_mins from 
(select * from 
(select *,row_number() over (partition by order_id order by diff) rnk from 
(select a.order_id,a.customer_id,a.roll_id,a.not_include_items,a.extra_items_included,a.order_date,
b.driver_id,b.pickup_time,b.distance,b.duration,b.cancellation,timestampdiff(minute,a.order_date,b.pickup_time) as diff
 from customer_orders a join driver_order b on a.order_id=b.order_id
where b.pickup_time is not null)a)b
where rnk =1)c
group by driver_id ;

-- 2. Is there any relationship between the number of rolls and how long the order takes to prepare ?
select order_id,count(roll_id) cnt ,round(sum(diff)/count(roll_id),0) tym from 
(select a.order_id,a.customer_id,a.roll_id,a.not_include_items,a.extra_items_included,a.order_date,
b.driver_id,b.pickup_time,b.distance,b.duration,b.cancellation,timestampdiff(minute,a.order_date,b.pickup_time) as diff
 from customer_orders a join driver_order b on a.order_id=b.order_id
where b.pickup_time is not null)a 
group by order_id;

-- 3. What was the average distance travelled for each customer?
 select customer_id,sum(distance)/count(order_id) avg_distance from
 (select * from 
 (select *,row_number() OVER (PArtition by order_id order by diff) rnk from
(select a.order_id,a.customer_id,a.roll_id,a.not_include_items,a.extra_items_included,a.order_date,
b.driver_id,b.pickup_time,trim(replace(b.distance,'km',' ')) distance
,b.duration,b.cancellation,timestampdiff(minute,a.order_date,b.pickup_time) as diff
 from customer_orders a join driver_order b on a.order_id=b.order_id
where b.pickup_time is not null)a)b
where rnk = 1)c
group by  customer_id;

-- 4. What was the difference between longest and shortest delivery times for all orders ?

select (max(duration) - min(duration)) as duration_gap from
(select duration or_duration ,case when  duration like '%min%' then left(duration,instr(duration,'m')-1)else duration
end as  duration  from driver_order where duration is not null)a ;

-- 5. What was the average speed for each driver for each delivery and do you notice any trends for these values ? 
select a.order_id,a.driver_id,distance/duration speed,b.cnt from 
(select order_id,driver_id,trim(replace(distance,'km',' ')) distance,case when  duration like '%min%' then left(duration,instr(duration,'m')-1)else duration
end as  duration from driver_order where distance is not null)a join 

(select order_id,count(roll_id) cnt from customer_orders group by order_id)b on a.order_id=b.order_id;

/* conclusion- As the number of rolls is increasing the speed is decreasing . */

-- 6. What is the successful delivery percantage for each driver ?
select driver_id,s/t cancelled_per from
(select driver_id,sum(cancel_per) s ,count(driver_id) t from 
(select driver_id,case when lower(cancellation) like '%cancel%' then 0 else 1 end as cancel_per from driver_order)a
group by driver_id)b;








