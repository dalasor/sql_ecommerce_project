WITH t1 AS (
    SELECT  o.order_id, 
            ARRAY_LENGTH(o.product_ids, 1) AS order_length, 
            u.user_id, 
            coalesce(TO_CHAR(birth_date, 'DD/MM/YYYY'), 'Not specified') AS birth_date,
            case 
                when date_part('year', age('2022-12-12'::DATE, birth_date)) between 18 and 24 then '18-24'
                when date_part('year', age('2022-12-12'::DATE, birth_date)) between 25 and 29 then '25-29'
                when date_part('year', age('2022-12-12'::DATE, birth_date)) between 30 and 35 then '30-35'
                when date_part('year', age('2022-12-12'::DATE, birth_date)) >= 36 then '36+'
                else 'Not specified'
            end as group_age
            
    FROM orders o
    INNER JOIN user_actions ua 
        ON o.order_id = ua.order_id
    INNER JOIN users u
        ON ua.user_id = u.user_id
    WHERE o.order_id NOT IN (
        SELECT order_id FROM user_actions
        WHERE action = 'cancel_order'
    )
)

SELECT  group_age, 
        COUNT(DISTINCT user_id) AS users_count,
        COUNT(order_id) AS orders_count,
        SUM(COUNT(DISTINCT user_id)) OVER()::INTEGER AS total_users_count,
        SUM(COUNT(order_id)) OVER()::INTEGER AS total_orders_count, 
        ROUND(AVG(order_length), 2) AS avg_orders_len

FROM t1
GROUP BY group_age
ORDER BY group_age