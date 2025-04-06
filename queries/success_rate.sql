SELECT  
        date_part('isodow', time)::int as weekday_number,
        to_char(time, 'Dy') as weekday,
        count(ua.order_id) filter (WHERE action = 'create_order') as created_orders,
        count(ua.order_id) filter (WHERE action = 'cancel_order') as canceled_orders,
        count(ua.order_id) filter (WHERE action = 'create_order') 
            - count(ua.order_id) filter (WHERE action = 'cancel_order') as actual_orders,
        round((count(ua.order_id) filter (WHERE action = 'create_order') 
            - count(ua.order_id) filter (WHERE action = 'cancel_order'))::decimal / 
            count(ua.order_id) filter (WHERE action = 'create_order'), 3) as success_rate,
        AVG(array_length(o.product_ids, 1)) FILTER (WHERE action = 'create_order') 
            AS avg_order_size,
        AVG(array_length(o.product_ids, 1)) FILTER (WHERE action = 'cancel_order') 
            AS avg_cancelled_order_size
            
FROM   user_actions ua
INNER JOIN orders o
    ON ua.order_id = o.order_id
WHERE  time >= '2022-08-24'
  and time < '2022-09-07'
GROUP BY weekday_number, weekday
ORDER BY weekday_number