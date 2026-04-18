-- ============================================================
--  STEP 3: ANALYTICS QUERIES
--  Run each section individually in SQL Workbench
--  Select the query you want → Ctrl+Shift+Enter to run it
-- ============================================================
USE ecommerce_dw;

-- ──────────────────────────────────────────────────────────
--  QUERY 1: MONTHLY REVENUE SUMMARY WITH MoM GROWTH
--
--  What it shows: total revenue each month, and whether
--  we grew or shrank compared to the previous month.
--
--  DE skills: CTE, LAG window function, ROUND, NULLIF
-- ──────────────────────────────────────────────────────────
WITH monthly AS (
    SELECT
        d.year,
        d.month,
        d.month_name,
        COUNT(DISTINCT fo.order_id)     AS total_orders,
        COUNT(DISTINCT fo.customer_sk)  AS unique_customers,
        ROUND(SUM(fo.total_amount), 2)  AS gross_revenue,
        ROUND(SUM(fo.discount_amount),2)AS total_discounts,
        ROUND(AVG(fo.total_amount), 2)  AS avg_order_value
    FROM fact_orders fo
    JOIN dim_date d ON d.date_key = fo.order_date_key
    WHERE fo.order_status NOT IN ('cancelled','returned')
    GROUP BY d.year, d.month, d.month_name
)
SELECT
    year,
    month,
    month_name,
    total_orders,
    unique_customers,
    gross_revenue,
    total_discounts,
    avg_order_value,
    -- Month-over-month revenue change (%)
    LAG(gross_revenue) OVER (ORDER BY year, month) AS prev_month_revenue,
    ROUND(
        100.0 * (gross_revenue - LAG(gross_revenue) OVER (ORDER BY year, month))
              / NULLIF(LAG(gross_revenue) OVER (ORDER BY year, month), 0)
    , 1)                                            AS mom_growth_pct
FROM monthly
ORDER BY year, month;


-- ──────────────────────────────────────────────────────────
--  QUERY 2: COHORT RETENTION — First Purchase Month
--
--  Groups customers by the month they first bought, then
--  shows what % came back in months 1, 2, 3, 6 afterwards.
--
--  DE skills: Multi-level CTEs, self-join, conditional SUM,
--             PERIOD_DIFF for month distance
-- ──────────────────────────────────────────────────────────
WITH first_purchase AS (
    -- Each customer's first order month
    SELECT
        fo.customer_sk,
        DATE_FORMAT(MIN(d.full_date), '%Y-%m-01') AS cohort_month
    FROM fact_orders fo
    JOIN dim_date d ON d.date_key = fo.order_date_key
    WHERE fo.order_status NOT IN ('cancelled','returned')
    GROUP BY fo.customer_sk
),
all_purchases AS (
    -- All orders with their order month
    SELECT
        fo.customer_sk,
        DATE_FORMAT(d.full_date, '%Y-%m-01') AS order_month
    FROM fact_orders fo
    JOIN dim_date d ON d.date_key = fo.order_date_key
    WHERE fo.order_status NOT IN ('cancelled','returned')
    GROUP BY fo.customer_sk, DATE_FORMAT(d.full_date, '%Y-%m-01')
),
cohort_data AS (
    SELECT
        fp.cohort_month,
        -- how many months after first purchase?
        PERIOD_DIFF(
            DATE_FORMAT(ap.order_month, '%Y%m'),
            DATE_FORMAT(fp.cohort_month,'%Y%m')
        )                           AS months_since_first,
        COUNT(DISTINCT ap.customer_sk) AS active_customers
    FROM first_purchase fp
    JOIN all_purchases ap ON ap.customer_sk = fp.customer_sk
    GROUP BY fp.cohort_month, months_since_first
),
cohort_size AS (
    SELECT cohort_month, active_customers AS cohort_size
    FROM cohort_data
    WHERE months_since_first = 0
)
SELECT
    cd.cohort_month,
    cs.cohort_size,
    -- Retention at each period as a percentage
    ROUND(100.0 * MAX(CASE WHEN months_since_first = 0 THEN active_customers END) / cs.cohort_size, 1) AS `Month 0`,
    ROUND(100.0 * MAX(CASE WHEN months_since_first = 1 THEN active_customers END) / cs.cohort_size, 1) AS `Month 1`,
    ROUND(100.0 * MAX(CASE WHEN months_since_first = 2 THEN active_customers END) / cs.cohort_size, 1) AS `Month 2`,
    ROUND(100.0 * MAX(CASE WHEN months_since_first = 3 THEN active_customers END) / cs.cohort_size, 1) AS `Month 3`,
    ROUND(100.0 * MAX(CASE WHEN months_since_first = 6 THEN active_customers END) / cs.cohort_size, 1) AS `Month 6`
FROM cohort_data cd
JOIN cohort_size cs USING (cohort_month)
GROUP BY cd.cohort_month, cs.cohort_size
ORDER BY cd.cohort_month;


-- ──────────────────────────────────────────────────────────
--  QUERY 3: RFM CUSTOMER SEGMENTATION
--
--  Scores every customer on:
--    R = Recency  (how recently they bought)
--    F = Frequency (how many orders)
--    M = Monetary  (how much they spent)
--  Then assigns a human-readable segment.
--
--  DE skills: NTILE, multi-CTE, CASE, business logic
-- ──────────────────────────────────────────────────────────
WITH rfm_base AS (
    SELECT
        c.customer_sk,
        c.first_name,
        c.last_name,
        c.email,
        c.customer_tier,
        DATEDIFF(CURDATE(), MAX(d.full_date))   AS recency_days,
        COUNT(DISTINCT fo.order_id)             AS frequency,
        ROUND(SUM(fo.total_amount), 2)          AS monetary
    FROM dim_customers c
    JOIN fact_orders fo ON fo.customer_sk = c.customer_sk
    JOIN dim_date d     ON d.date_key = fo.order_date_key
    WHERE fo.order_status NOT IN ('cancelled','returned')
      AND c.is_current = 1
    GROUP BY c.customer_sk, c.first_name, c.last_name, c.email, c.customer_tier
),
rfm_scores AS (
    SELECT
        *,
        -- R: lower recency days = better = higher score
        6 - NTILE(5) OVER (ORDER BY recency_days)  AS r_score,
        NTILE(5) OVER (ORDER BY frequency)          AS f_score,
        NTILE(5) OVER (ORDER BY monetary)           AS m_score
    FROM rfm_base
),
rfm_segmented AS (
    SELECT
        *,
        CASE
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
            WHEN r_score >= 3 AND f_score >= 3                  THEN 'Loyal Customers'
            WHEN r_score >= 4 AND f_score <= 2                  THEN 'Recent Customers'
            WHEN r_score >= 3 AND f_score <= 2 AND m_score >= 3 THEN 'Potential Loyalists'
            WHEN r_score <= 2 AND f_score >= 3 AND m_score >= 3 THEN 'At Risk'
            WHEN r_score = 1  AND f_score >= 4                  THEN 'Cannot Lose Them'
            WHEN r_score <= 2 AND f_score <= 2                  THEN 'Hibernating'
            ELSE 'Needs Attention'
        END AS segment
    FROM rfm_scores
)
SELECT
    segment,
    COUNT(*)                                         AS customers,
    ROUND(AVG(recency_days))                         AS avg_days_since_purchase,
    ROUND(AVG(frequency), 1)                         AS avg_orders,
    ROUND(AVG(monetary), 2)                          AS avg_lifetime_value,
    ROUND(SUM(monetary), 2)                          AS total_segment_revenue,
    ROUND(100.0 * SUM(monetary)
               / SUM(SUM(monetary)) OVER (), 1)      AS pct_of_total_revenue
FROM rfm_segmented
GROUP BY segment
ORDER BY total_segment_revenue DESC;


-- ──────────────────────────────────────────────────────────
--  QUERY 4: TOP 3 PRODUCTS BY REVENUE IN EACH CATEGORY
--
--  Shows the 3 best-selling products within every category,
--  including their gross margin percentage.
--
--  DE skills: DENSE_RANK with PARTITION BY, CTE
-- ──────────────────────────────────────────────────────────
WITH product_revenue AS (
    SELECT
        p.category,
        p.product_name,
        p.brand,
        SUM(oi.line_revenue)   AS revenue,
        SUM(oi.gross_margin)   AS gross_margin,
        SUM(oi.quantity)       AS units_sold,
        COUNT(DISTINCT fo.order_id) AS order_count
    FROM fact_order_items oi
    JOIN dim_products p  ON p.product_sk  = oi.product_sk
    JOIN fact_orders  fo ON fo.order_sk   = oi.order_sk
    WHERE fo.order_status NOT IN ('cancelled','returned')
    GROUP BY p.category, p.product_name, p.brand
),
ranked AS (
    SELECT
        *,
        DENSE_RANK() OVER (
            PARTITION BY category
            ORDER BY revenue DESC
        ) AS rank_in_category
    FROM product_revenue
)
SELECT
    category,
    rank_in_category,
    product_name,
    brand,
    ROUND(revenue, 2)                                  AS revenue,
    ROUND(gross_margin, 2)                             AS gross_margin,
    ROUND(100.0 * gross_margin / NULLIF(revenue,0), 1) AS margin_pct,
    units_sold,
    order_count
FROM ranked
WHERE rank_in_category <= 3
ORDER BY category, rank_in_category;


-- ──────────────────────────────────────────────────────────
--  QUERY 5: PROMO CODE EFFECTIVENESS
--
--  Did the promotions actually increase revenue or just
--  give away margin? Compares promo vs non-promo orders.
--
--  DE skills: LEFT JOIN, GROUP BY, business KPIs
-- ──────────────────────────────────────────────────────────
SELECT
    COALESCE(pr.promo_code, 'No Promo')     AS promo_code,
    COALESCE(pr.promo_type, 'organic')      AS promo_type,
    COUNT(DISTINCT fo.order_id)             AS orders,
    COUNT(DISTINCT fo.customer_sk)          AS unique_customers,
    ROUND(AVG(fo.total_amount), 2)          AS avg_order_value,
    ROUND(AVG(fo.discount_amount), 2)       AS avg_discount,
    ROUND(AVG(fo.total_amount - fo.discount_amount), 2) AS avg_net_revenue,
    ROUND(SUM(fo.total_amount), 2)          AS total_gross_revenue,
    ROUND(SUM(fo.discount_amount), 2)       AS total_discount_given,
    -- New customers acquired through this promo
    SUM(fo.is_first_order)                  AS new_customers_acquired,
    ROUND(100.0 * SUM(fo.is_first_order)
               / COUNT(*), 1)              AS new_customer_pct
FROM fact_orders fo
LEFT JOIN dim_promotions pr ON pr.promo_sk = fo.promo_sk
WHERE fo.order_status NOT IN ('cancelled','returned')
GROUP BY pr.promo_code, pr.promo_type
ORDER BY total_gross_revenue DESC;


-- ──────────────────────────────────────────────────────────
--  QUERY 6: GEOGRAPHIC REVENUE BREAKDOWN (YoY)
--
--  Which states drive the most revenue?
--  Did they grow year over year?
--
--  DE skills: Conditional aggregation (SUM CASE WHEN),
--             YoY growth calculation, RANK
-- ──────────────────────────────────────────────────────────
SELECT
    c.state_code,
    -- 2023 metrics
    COUNT(DISTINCT CASE WHEN d.year = 2023 THEN fo.order_id END)     AS orders_2023,
    ROUND(SUM(CASE WHEN d.year = 2023 THEN fo.total_amount ELSE 0 END), 2) AS revenue_2023,
    -- 2024 metrics
    COUNT(DISTINCT CASE WHEN d.year = 2024 THEN fo.order_id END)     AS orders_2024,
    ROUND(SUM(CASE WHEN d.year = 2024 THEN fo.total_amount ELSE 0 END), 2) AS revenue_2024,
    -- YoY growth %
    ROUND(100.0 * (
        SUM(CASE WHEN d.year = 2024 THEN fo.total_amount ELSE 0 END)
      - SUM(CASE WHEN d.year = 2023 THEN fo.total_amount ELSE 0 END)
    ) / NULLIF(SUM(CASE WHEN d.year = 2023 THEN fo.total_amount ELSE 0 END), 0)
    , 1)                                                             AS yoy_growth_pct,
    -- State's share of all-time revenue
    ROUND(100.0 * SUM(fo.total_amount)
               / SUM(SUM(fo.total_amount)) OVER (), 2)              AS pct_of_total,
    RANK() OVER (ORDER BY SUM(fo.total_amount) DESC)                AS revenue_rank
FROM fact_orders fo
JOIN dim_customers c ON c.customer_sk = fo.customer_sk AND c.is_current = 1
JOIN dim_date d      ON d.date_key = fo.order_date_key
WHERE fo.order_status NOT IN ('cancelled','returned')
GROUP BY c.state_code
ORDER BY revenue_rank;


-- ──────────────────────────────────────────────────────────
--  QUERY 7: RUNNING TOTAL & CUMULATIVE % OF ANNUAL REVENUE
--
--  The Pareto principle: do 20% of days drive 80% revenue?
--  Shows cumulative revenue sorted by best day first.
--
--  DE skills: SUM() OVER with ORDER BY (running total),
--             cumulative percentage threshold
-- ──────────────────────────────────────────────────────────
WITH daily_rev AS (
    SELECT
        d.full_date,
        d.day_name,
        d.is_weekend,
        ROUND(SUM(fo.total_amount), 2) AS daily_revenue
    FROM fact_orders fo
    JOIN dim_date d ON d.date_key = fo.order_date_key
    WHERE fo.order_status NOT IN ('cancelled','returned')
      AND d.year = 2024
    GROUP BY d.full_date, d.day_name, d.is_weekend
)
SELECT
    full_date,
    day_name,
    is_weekend,
    daily_revenue,
    -- Running total (best day first)
    ROUND(SUM(daily_revenue) OVER (
        ORDER BY daily_revenue DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ), 2)                                         AS running_total,
    -- What % of annual revenue is captured so far?
    ROUND(100.0 * SUM(daily_revenue) OVER (
        ORDER BY daily_revenue DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) / SUM(daily_revenue) OVER (), 1)            AS cumulative_pct
FROM daily_rev
ORDER BY daily_revenue DESC
LIMIT 50;


-- ──────────────────────────────────────────────────────────
--  QUERY 8: ETL AUDIT — DATA QUALITY CHECKS
--
--  Before loading into a warehouse, a Data Engineer always
--  validates the data. This query is a standard QA check.
--
--  DE skills: UNION ALL for multi-check output, COUNT,
--             referential integrity validation
-- ──────────────────────────────────────────────────────────
SELECT 'Orders with NULL customer'     AS check_name,
       COUNT(*)                        AS issue_count
FROM fact_orders WHERE customer_sk IS NULL

UNION ALL

SELECT 'Orders with negative total',
       COUNT(*)
FROM fact_orders WHERE total_amount < 0

UNION ALL

SELECT 'Items with quantity = 0',
       COUNT(*)
FROM fact_order_items WHERE quantity <= 0

UNION ALL

SELECT 'Orders missing from dim_date',
       COUNT(*)
FROM fact_orders fo
LEFT JOIN dim_date d ON d.date_key = fo.order_date_key
WHERE d.date_key IS NULL

UNION ALL

SELECT 'Duplicate order IDs',
       COUNT(*) - COUNT(DISTINCT order_id)
FROM fact_orders

UNION ALL

SELECT 'Products with negative margin',
       COUNT(*)
FROM fact_order_items WHERE gross_margin < 0

UNION ALL

SELECT 'Orders with impossible date (future)',
       COUNT(*)
FROM fact_orders fo
JOIN dim_date d ON d.date_key = fo.order_date_key
WHERE d.full_date > CURDATE();
