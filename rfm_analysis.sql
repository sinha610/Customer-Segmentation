-- purchase frequency
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

-- total purchases
cnt_trans as (
	select amperity_id as cust_id,
		count(fk_store_txn) + count(fk_web_txn) as total_purchases
	from transaction_practice_dummy
	where is_return = 0 and is_cancellation = 0
	group by amperity_id
),

-- recency
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

-- monetary
monetary as (
	select amperity_id as cust_id,
		round(sum(item_cost), 2) as revenue_generated
	from transaction_practice_dummy
	where is_return = 0 and is_cancellation = 0
	group by amperity_id
),

-- rfm base
rfm_base as (
	select 
		c.cust_id,
		c.total_purchases,
		r.last_purchased,
		m.revenue_generated,
		p.purchase_freq,
		p.customer_purchase_pattern
	from cnt_trans c
	join recency r on c.cust_id = r.cust_id
	join monetary m on c.cust_id = m.cust_id
	left join purchase_freq p on c.cust_id = p.cust_id
),

-- rfm scores
rfm_score as (
	select *,
		ntile(5) over (order by last_purchased asc) as r_score,
		ntile(5) over (order by total_purchases desc) as f_score,
		ntile(5) over (order by revenue_generated desc) as m_score
	from rfm_base
),

-- rfm labels
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

-- final output
select * from label;
