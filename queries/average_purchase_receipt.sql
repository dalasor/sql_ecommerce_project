-- Средний чек

WITH t1 AS (
    SELECT  o.order_id,
            u.user_id,
            SUM(p.price) AS order_price,
            ARRAY_LENGTH(o.product_ids, 1) AS order_size,
            ARRAY_AGG(p.name) AS product_names
    FROM (
        SELECT order_id, product_ids, unnest(product_ids) AS product_id
        FROM orders
        WHERE order_id NOT IN (
            SELECT order_id FROM user_actions
            WHERE action = 'cancel_order'
        )
    ) o
    LEFT JOIN products p
        ON o.product_id = p.product_id
    LEFT JOIN user_actions ua
        ON o.order_id = ua.order_id
    INNER JOIN users u
        ON ua.user_id = u.user_id
    GROUP BY o.order_id, o.product_ids, u.user_id
    ORDER BY order_price DESC
    
), t2 AS (
    SELECT  user_id,
            COUNT(order_id) AS total_orders,
            SUM(order_price) AS total_price,
            SUM(order_size) AS total_products
    FROM t1
    GROUP BY user_id
    ORDER BY total_price DESC, total_orders DESC, user_id ASC

), avg1 AS (
    -- средний чек на основе группировки по каждому юзеру
    SELECT
    
        AVG(total_orders) AS avg_total_orders,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_orders) AS median_orders,
        MIN(total_orders) AS min_total_orders,
        MAX(total_orders) AS max_total_orders,
        
        AVG(total_price) AS avg_total_price,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_price) AS median_price,
        MIN(total_price) AS min_total_price,
        MAX(total_price) AS max_total_price
        
    FROM t2
    
), avg2 AS (
    -- средний чек на основе исходной t1
    SELECT
        
        AVG(order_price) AS avg_total_price,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY order_price) AS median_price,
        MIN(order_price) AS min_total_price,
        MAX(order_price) AS max_total_price
        
    FROM t1
)

SELECT * FROM avg2