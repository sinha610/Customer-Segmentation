
-- Purchase frequency
with purchase_freq as (
	select c.cust_id,
		avg(c.day_diff_from_lastorder) as purchase_freq,
        case 
			when avg(c.day_diff_from_lastorder) in (0,1) then 'Not Sure'
			when avg(c.day_diff_from_lastorder) between 2 and 10 then 'Frequent Purchaser'
			when avg(c.day_diff_from_lastorder) between 11 and 30 then 'Regular Customer'
			when avg(c.day_diff_from_lastorder) > 30 and avg(c.day_diff_from_lastorder) < 60 then 'Irregular Customer'
			else 'No Pattern'
		end as customer_purchase_pattern 
	from (
		select b.cust_id, b.order_datetime, b.last_date,
			datediff(b.last_date, b.order_datetime) as day_diff_from_lastorder
		from (
			select a.cust_id, a.order_datetime,
				lag(a.order_datetime,1) over (partition by a.cust_id order by a.order_datetime desc) as last_date
			from (
				select amperity_id as cust_id, order_datetime
				from transaction_practice_dummy
				where is_return = 0 and is_cancellation = 0
			) a
		) b
	) c
	where day_diff_from_lastorder is not null
	group by c.cust_id
),

-- Total purchases
cnt_trans as (
	select amperity_id as cust_id,
		count(fk_store_txn) + count(fk_web_txn) as total_purchases
	from transaction_practice_dummy
	where is_return = 0 and is_cancellation = 0
	group by amperity_id
),

-- Recency
recency as (
	select cust_id,
		datediff(curdate(), max(order_datetime)) as last_purchased
	from (
		select amperity_id as cust_id, order_datetime
		from transaction_practice_dummy
		where is_return = 0 and is_cancellation = 0
	) t
	group by cust_id
),

-- Monetary
monetary as (
	select amperity_id as cust_id,
		round(sum(item_list_price), 2) as revenue_generated
	from transaction_practice_dummy
	where is_return = 0 and is_cancellation = 0
	group by amperity_id
),

-- Average discount
avg_discount as (
	select amperity_id as cust_id,
		round(avg(item_discount_percent), 2) as avg_discount_percent
	from transaction_practice_dummy
	where is_return = 0 and is_cancellation = 0
	group by amperity_id
),

-- Profit
profit as (
	select amperity_id as cust_id,
		sum(item_profit) as total_profit,
		round(avg(item_profit), 2) as avg_profit 
	from transaction_practice_dummy
	where is_return = 0 and is_cancellation = 0
	group by amperity_id
),

-- Channel preference
channel_pref as (
	select *,
		case
			when online_orders > 0 and sof_orders > 0 and call_centre_orders > 0 then 'All Three'
			when online_orders > 0 and sof_orders = 0 and call_centre_orders = 0 then 'Online Only'
			when sof_orders > 0 and online_orders = 0 and call_centre_orders = 0 then 'SOF Only'
			when call_centre_orders > 0 and online_orders = 0 and sof_orders = 0 then 'Call Centre Only'
			when online_orders > 0 and sof_orders > 0 and call_centre_orders = 0 then 'Online + SOF'
			when online_orders > 0 and call_centre_orders > 0 and sof_orders = 0 then 'Online + Call Centre'
			when sof_orders > 0 and call_centre_orders > 0 and online_orders = 0 then 'SOF + Call Centre'
			else 'Unknown'
		end as channel_type
	from (
		select amperity_id as cust_id,
			count(distinct case when lower(purchase_channel) = 'online' then order_id end) as online_orders,
			count(distinct case when lower(purchase_channel) = 'sof' then order_id end) as sof_orders,
			count(distinct case when lower(purchase_channel) = 'call center' then order_id end) as call_centre_orders
		from transaction_practice_dummy
		where is_return = 0 and is_cancellation = 0
		group by amperity_id
	) base
),

-- Return rate
return_rate as (
	select amperity_id as cust_id,
		round(sum(case when is_return = 1 then 1 else 0 end) * 1.0 / count(order_id), 2) as return_rate
	from transaction_practice_dummy
	group by amperity_id
),

-- Time trend
time_summary as (
	select amperity_id as cust_id,
		count(distinct date_format(order_datetime, '%Y-%m')) as active_months,
		min(order_datetime) as first_order_date,
		max(order_datetime) as last_order_date
	from transaction_practice_dummy
	where is_return = 0 and is_cancellation = 0
	group by amperity_id
),

-- Base table
rfm_base as (
	select 
		c.cust_id,
		c.total_purchases,
		r.last_purchased,
		m.revenue_generated,
		p.purchase_freq,
		p.customer_purchase_pattern,
		ad.avg_discount_percent,
		pr.total_profit,
		pr.avg_profit,
		case when c.total_purchases > 1 then 'Repeat Buyer' else 'One Time Buyer' end as purchase_type,
		cr.channel_type,
		rr.return_rate,
		ts.active_months,
		ts.first_order_date,
		ts.last_order_date
	from cnt_trans c
	left join recency r on c.cust_id = r.cust_id
	left join monetary m on c.cust_id = m.cust_id
	left join purchase_freq p on c.cust_id = p.cust_id
	left join avg_discount ad on c.cust_id = ad.cust_id
	left join profit pr on c.cust_id = pr.cust_id
	left join channel_pref cr on c.cust_id = cr.cust_id
	left join return_rate rr on c.cust_id = rr.cust_id
	left join time_summary ts on c.cust_id = ts.cust_id
),

-- Scoring
rfm_score as (
	select *,
		ntile(5) over (order by last_purchased asc) as r_score,
		ntile(5) over (order by total_purchases desc) as f_score,
		ntile(5) over (order by revenue_generated desc) as m_score
	from rfm_base
),

-- Final labels
label as (
	select *,
		case
			when r_score >= 4 and f_score >= 4 and m_score >= 4 then 'Loyal'
			when r_score >= 4 and f_score >= 3 then 'Potential Loyalist'
			when r_score = 5 and f_score <= 2 then 'Recent Customers'
			when r_score between 2 and 3 and f_score between 2 and 3 then 'Need Attention'
			when r_score = 2 and f_score = 1 then 'About to Sleep'
			when r_score = 1 and f_score >= 2 then 'At Risk'
			when r_score = 1 and f_score = 1 and m_score <= 2 then 'Hibernating'
			else 'Lost'
		end as rfm_segment
	from rfm_score
)

-- Final output
select * from label;
