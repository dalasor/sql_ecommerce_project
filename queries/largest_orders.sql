-- КТо оформлял и доставлял самые большие заказы

WITH last_date as (
    SELECT time::date
    FROM user_actions
    ORDER BY time desc limit 1

), uo as (
    SELECT order_id,
           user_id
    FROM user_actions
    WHERE action = 'create_order'
        AND order_id NOT IN (
            SELECT order_id
            FROM   user_actions
            WHERE  action = 'cancel_order'
        )
)

SELECT DISTINCT order_id,
        user_id,
        date_part('year', age((SELECT * FROM last_date), u.birth_date))::integer as user_age,
        courier_id, 
        date_part('year', age((SELECT * FROM   last_date), c.birth_date))::integer as courier_age
        
FROM uo
    LEFT JOIN orders o using(order_id)
    LEFT JOIN courier_actions ca using(order_id)
    LEFT JOIN users u using(user_id)
    LEFT JOIN couriers c using(courier_id)
WHERE  array_length(product_ids, 1) = (SELECT max(array_length(product_ids, 1)) FROM   orders)
ORDER BY order_id