-- Сравнение среднего времени доставки заказа, для заказов с большим количеством товаров, 
-- и с более маленьким, и понять, есть ли существенная разница, а также насколько она статистически значима

-- Также можно выяснить сколько в процентном соотношении людей, отменяют заказы, 
-- и посмотреть есть ли связь с количеством товаров в таком заказе


with tab AS (
    SELECT order_id
    FROM   courier_actions
    WHERE  action = 'accept_order'
        -- AND order_id in (
        --     SELECT order_id
        --     FROM   orders
        --     WHERE  array_length(product_ids, 1) < 5
        -- )
        AND order_id not in (
            SELECT order_id
            FROM   user_actions
            WHERE  action = 'cancel_order')

), time AS (
    SELECT  order_id,
            CASE 
                WHEN array_length(product_ids, 1) > 5 THEN 'large' 
                ELSE 'small' 
            END AS order_size,
            MIN(time) as time_accepted,
            MAX(time) as time_delivered,
            ROUND(extract(epoch FROM age(max(time), min(time)))::decimal / 60, 0)::INTEGER AS delivery_time
    FROM   courier_actions
    LEFT JOIN orders USING(order_id) 
    WHERE  order_id in (SELECT order_id FROM tab)
    GROUP BY order_id, product_ids
    ORDER BY order_id
    
), stats AS (
    SELECT  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY delivery_time) AS median,

        -- small orders
        COUNT(CASE WHEN order_size = 'small' THEN 1 END) AS orders_count_small,
        ROUND(AVG(CASE WHEN order_size = 'small' THEN delivery_time END), 2) AS mean_small,
        STDDEV(CASE WHEN order_size = 'small' THEN delivery_time END) AS std_small,
        MIN(CASE WHEN order_size = 'small' THEN delivery_time END) AS min_small,
        MAX(CASE WHEN order_size = 'small' THEN delivery_time END) AS max_small,
        
        -- large orders
        COUNT(CASE WHEN order_size = 'large' THEN 1 END) AS orders_count_large,
        ROUND(AVG(CASE WHEN order_size = 'large' THEN delivery_time END), 2) AS mean_large,
        STDDEV(CASE WHEN order_size = 'large' THEN delivery_time END) AS std_large,
        MIN(CASE WHEN order_size = 'large' THEN delivery_time END) AS min_large,
        MAX(CASE WHEN order_size = 'large' THEN delivery_time END) AS max_large
        
    FROM time
    
), z_test AS (
    SELECT
        mean_small,
        mean_large,
        SQRT(
            (std_small^2 * orders_count_small + std_large^2 * orders_count_large)
            / (orders_count_small + orders_count_large)
        ) AS pooled_std,
        SQRT(POWER(std_small, 2)/orders_count_small + POWER(std_large, 2)/orders_count_large) AS se,
        (mean_large - mean_small) / (SQRT(POWER(std_small, 2)/orders_count_small + POWER(std_large, 2)/orders_count_large)) AS z_score,
        1 / (1 + 0.2316419 * ABS((mean_large - mean_small) / (SQRT(POWER(std_small, 2)/orders_count_small + POWER(std_large, 2)/orders_count_large)))) AS t 
    FROM stats
)

-- SELECT * FROM stats;

-- SELECT * FROM time;

SELECT
  -- Разница средних
  mean_large - mean_small AS mean_diff,
  
  -- Cohen’s d
  ABS(mean_large - mean_small) / pooled_std AS cohen_d,
  
  -- 95% ДИ
  (mean_large - mean_small) - 1.96 * se AS ci_lower,
  (mean_large - mean_small) + 1.96 * se AS ci_upper,
  
  -- z-статистика и p-value
  z_score,
  2 * (1 - (
    CASE 
        WHEN z_score >= 0 THEN
            1 - (1 / SQRT(2 * PI())) * EXP(-(z_score^2)/2) * 
            (0.319381530 * t - 0.356563782 * t^2 + 1.781477937 * t^3 - 1.821255978 * t^4 + 1.330274429 * t^5)
        ELSE
            (1 / SQRT(2 * PI())) * EXP(-(z_score^2)/2) * 
            (0.319381530 * t - 0.356563782 * t^2 + 1.781477937 * t^3 - 1.821255978 * t^4 + 1.330274429 * t^5)
    END
    )) AS p_value
  
FROM z_test