WITH t1 AS (
    SELECT  user_id,
            COUNT(DISTINCT order_id) FILTER (WHERE action = 'cancel_order') AS cancel_orders,
            COUNT(DISTINCT order_id) AS orders_count,
            ROUND(COUNT(DISTINCT order_id) FILTER (WHERE action = 'cancel_order')::DECIMAL / COUNT(DISTINCT order_id), 2) AS cancel_rate,
            SUM(COUNT(DISTINCT order_id)) OVER() AS total_orders,
            SUM(COUNT(DISTINCT order_id) FILTER (WHERE action = 'cancel_order')) OVER() AS total_cancels
    FROM user_actions
    GROUP BY user_id
)

SELECT  cancel_orders,
        SUM(orders_count)::INTEGER AS sum_orders_count,
        COUNT(user_id) AS users,
        ROUND(AVG(cancel_rate), 2) AS avg_cancel_rate,
        -- (SELECT SUM(cancel_rate) / COUNT(user_id) FROM t1) AS avg_cancel_rate_total,
        -- Взвешенное среднее: общие отмены / общие заказы
        ROUND(total_cancels::DECIMAL / total_orders, 2) AS avg_cancel_rate_total
FROM t1
GROUP BY cancel_orders, total_orders, total_cancels
ORDER BY cancel_orders ASC