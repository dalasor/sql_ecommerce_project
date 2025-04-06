SELECT  product_id,
        name,
        price,
        times_purchased,
        price * times_purchased AS product_revenue,
        SUM(price * times_purchased) OVER () AS total_revenue,
        price * times_purchased / SUM(price * times_purchased) OVER() * 100 AS revenue_percentage,
        CORR(price, times_purchased) OVER() AS price_sales_corr,
        CORR(price, price * times_purchased) OVER() AS price_revenue_corr,
        CORR(times_purchased, price * times_purchased) OVER() AS sales_revenue_corr
FROM    (
    SELECT UNNEST(product_ids) AS product_id,
           COUNT(*) AS times_purchased
    FROM   orders
    WHERE  order_id NOT IN (SELECT order_id
                            FROM   user_actions
                            WHERE  action = 'cancel_order')
    GROUP BY product_id
    ORDER BY times_purchased DESC
) t
LEFT JOIN products USING(product_id)
ORDER BY revenue_percentage DESC