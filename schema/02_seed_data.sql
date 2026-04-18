-- ============================================================
--  STEP 2 (FIXED): SEED DATA — No stored procedure loop
--  Much faster — runs in under 5 seconds
-- ============================================================
USE ecommerce_dw;

-- ── 1. Promotions ─────────────────────────────────────────
INSERT INTO dim_promotions (promo_code, promo_name, promo_type, discount_value, min_order_value, starts_at, ends_at)
VALUES
    ('WELCOME10', 'New Customer 10% Off',      'percentage', 0.10,  0.00, '2023-01-01', '2024-12-31'),
    ('SUMMER25',  'Summer Sale 25% Off',        'percentage', 0.25, 50.00, '2023-06-01', '2023-08-31'),
    ('FLAT20',    '$20 Off Orders Over $100',   'flat',       20.00,100.00,'2023-09-01', '2023-09-30'),
    ('FREESHIP',  'Free Shipping Month',        'free_shipping',0,   0.00, '2023-11-01', '2023-11-30'),
    ('BFCM30',    'Black Friday 30% Off',       'percentage', 0.30, 75.00, '2023-11-24', '2023-11-27'),
    ('NY2024',    'New Year $15 Off',           'flat',       15.00,60.00, '2024-01-01', '2024-01-07'),
    ('VIP15',     'VIP Members 15% Off',        'percentage', 0.15,  0.00, '2024-01-01', '2024-12-31'),
    ('SPRING20',  'Spring Refresh 20% Off',     'percentage', 0.20, 40.00, '2024-03-20', '2024-05-31'),
    ('SUMMER30',  'Summer 2024 30% Off',        'percentage', 0.30, 60.00, '2024-06-01', '2024-08-31'),
    ('BFCM35',    'Black Friday 2024 35% Off',  'percentage', 0.35, 80.00, '2024-11-28', '2024-12-02');

-- ── 2. Products ───────────────────────────────────────────
INSERT INTO dim_products (product_id, sku, product_name, category, subcategory, brand, unit_cost, unit_price, launched_on)
VALUES
    (UUID(),'SKU-E001','Wireless Noise-Cancelling Headphones','Electronics','Audio',       'SoundWave',  45.00,129.99,'2022-03-15'),
    (UUID(),'SKU-E002','USB-C Fast Charger 65W',              'Electronics','Accessories', 'ChargeTech',  8.50, 34.99,'2022-06-01'),
    (UUID(),'SKU-E003','Mechanical Keyboard TKL',             'Electronics','Peripherals', 'KeyMaster',  38.00, 99.99,'2022-09-10'),
    (UUID(),'SKU-E004','Smart LED Desk Lamp',                 'Electronics','Lighting',    'LumiTech',   18.00, 59.99,'2023-01-20'),
    (UUID(),'SKU-E005','Portable Bluetooth Speaker',          'Electronics','Audio',       'SoundWave',  22.00, 79.99,'2023-04-05'),
    (UUID(),'SKU-A001','Classic Crew Neck Sweatshirt',        'Apparel',    'Tops',        'UrbanThread', 14.00, 49.99,'2022-08-01'),
    (UUID(),'SKU-A002','Slim Fit Chino Pants',                'Apparel',    'Bottoms',     'UrbanThread', 18.00, 69.99,'2022-08-01'),
    (UUID(),'SKU-A003','Puffer Jacket Lightweight',           'Apparel',    'Outerwear',   'NorthEdge',  35.00,119.99,'2022-10-15'),
    (UUID(),'SKU-A004','Performance Running Shorts',          'Apparel',    'Activewear',  'SwiftFit',   10.00, 39.99,'2023-02-10'),
    (UUID(),'SKU-A005','Merino Wool Beanie',                  'Apparel',    'Accessories', 'WoolCo',      6.50, 29.99,'2023-09-01'),
    (UUID(),'SKU-H001','Stainless Steel Water Bottle 32oz',   'Home',       'Drinkware',   'HydroCore',   9.00, 34.99,'2022-05-20'),
    (UUID(),'SKU-H002','Non-Stick Cast Iron Skillet 10in',    'Home',       'Cookware',    'IronChef',   22.00, 64.99,'2022-07-15'),
    (UUID(),'SKU-H003','Bamboo Cutting Board Set 3-piece',    'Home',       'Prep',        'EcoKitchen',  12.00, 44.99,'2023-03-01'),
    (UUID(),'SKU-H004','Pour-Over Coffee Maker',              'Home',       'Coffee',      'BrewMaster',  14.00, 49.99,'2023-05-15'),
    (UUID(),'SKU-H005','Scented Soy Candle Set 4-pack',       'Home',       'Decor',       'AromaLux',    8.00, 39.99,'2023-07-01'),
    (UUID(),'SKU-S001','Yoga Mat 6mm Non-Slip',               'Sports',     'Yoga',        'ZenFlex',    16.00, 54.99,'2022-01-10'),
    (UUID(),'SKU-S002','Resistance Bands Set 5 levels',       'Sports',     'Fitness',     'StrengthPro', 7.00, 29.99,'2022-04-01'),
    (UUID(),'SKU-S003','Hiking Backpack 30L',                 'Sports',     'Outdoor',     'TrailBlaze',  42.00,139.99,'2022-11-01'),
    (UUID(),'SKU-S004','Foam Roller High Density',            'Sports',     'Recovery',    'RecoverX',    9.00, 34.99,'2023-02-20'),
    (UUID(),'SKU-S005','Insulated Hydration Vest',            'Sports',     'Outdoor',     'TrailBlaze',  28.00, 89.99,'2024-01-15');

-- ── 3. Customers ──────────────────────────────────────────
INSERT INTO dim_customers (customer_id, email, first_name, last_name, city, state_code, customer_tier, acquisition_channel, effective_from)
VALUES
    (UUID(),'james.smith@email.com',      'James',     'Smith',     'New York',    'NY','standard','organic_search','2023-01-05'),
    (UUID(),'emma.johnson@email.com',     'Emma',      'Johnson',   'Los Angeles', 'CA','silver',  'paid_social',   '2023-01-12'),
    (UUID(),'liam.williams@email.com',    'Liam',      'Williams',  'Chicago',     'IL','gold',    'email',         '2023-01-20'),
    (UUID(),'olivia.brown@email.com',     'Olivia',    'Brown',     'Houston',     'TX','standard','referral',      '2023-02-03'),
    (UUID(),'noah.jones@email.com',       'Noah',      'Jones',     'Phoenix',     'AZ','vip',     'paid_search',   '2023-02-14'),
    (UUID(),'ava.garcia@email.com',       'Ava',       'Garcia',    'Philadelphia','PA','standard','direct',        '2023-02-28'),
    (UUID(),'william.miller@email.com',   'William',   'Miller',    'San Antonio', 'TX','silver',  'organic_search','2023-03-10'),
    (UUID(),'sophia.davis@email.com',     'Sophia',    'Davis',     'San Diego',   'CA','gold',    'paid_social',   '2023-03-22'),
    (UUID(),'benjamin.wilson@email.com',  'Benjamin',  'Wilson',    'Dallas',      'TX','standard','email',         '2023-04-05'),
    (UUID(),'isabella.anderson@email.com','Isabella',  'Anderson',  'San Jose',    'CA','vip',     'referral',      '2023-04-18'),
    (UUID(),'lucas.thomas@email.com',     'Lucas',     'Thomas',    'Austin',      'TX','silver',  'organic_search','2023-05-02'),
    (UUID(),'mia.jackson@email.com',      'Mia',       'Jackson',   'Seattle',     'WA','standard','paid_search',   '2023-05-15'),
    (UUID(),'henry.white@email.com',      'Henry',     'White',     'Denver',      'CO','gold',    'direct',        '2023-06-01'),
    (UUID(),'charlotte.harris@email.com', 'Charlotte', 'Harris',    'Nashville',   'TN','standard','paid_social',   '2023-06-20'),
    (UUID(),'alexander.martin@email.com', 'Alexander', 'Martin',    'Portland',    'OR','vip',     'email',         '2023-07-08'),
    (UUID(),'amelia.thompson@email.com',  'Amelia',    'Thompson',  'Las Vegas',   'NV','silver',  'organic_search','2023-07-25'),
    (UUID(),'mason.moore@email.com',      'Mason',     'Moore',     'Boston',      'MA','gold',    'referral',      '2023-08-10'),
    (UUID(),'harper.young@email.com',     'Harper',    'Young',     'Atlanta',     'GA','standard','paid_search',   '2023-08-28'),
    (UUID(),'ethan.lee@email.com',        'Ethan',     'Lee',       'Miami',       'FL','vip',     'direct',        '2023-09-15'),
    (UUID(),'evelyn.walker@email.com',    'Evelyn',    'Walker',    'Minneapolis', 'MN','standard','paid_social',   '2023-10-02');

-- SCD2: expire 3 silver customers, re-insert as gold
UPDATE dim_customers
SET    effective_to = '2023-12-31', is_current = 0
WHERE  email IN ('emma.johnson@email.com','william.miller@email.com','amelia.thompson@email.com')
  AND  is_current = 1;

INSERT INTO dim_customers
    (customer_id, email, first_name, last_name, city, state_code,
     customer_tier, acquisition_channel, effective_from, effective_to, is_current)
SELECT customer_id, email, first_name, last_name, city, state_code,
       'gold', acquisition_channel, '2024-01-01', '9999-12-31', 1
FROM   dim_customers
WHERE  email IN ('emma.johnson@email.com','william.miller@email.com','amelia.thompson@email.com')
  AND  effective_to = '2023-12-31';

-- ── 4. Orders (direct INSERT — no loop, runs instantly) ───
-- We use a cross join trick to generate many rows from few seed rows
-- Then immediately insert items and link them up

INSERT INTO fact_orders
    (order_id, customer_sk, promo_sk, order_date_key,
     order_status, channel, subtotal, discount_amount, shipping_fee, tax_amount, item_count, is_first_order)
SELECT
    UUID()                                          AS order_id,
    c.customer_sk,
    IF(MOD(seq.n, 3) = 0, p.promo_sk, NULL)        AS promo_sk,
    -- Spread orders across 2023–2024
    CASE
        WHEN MOD(seq.n, 8) = 0 THEN 20231124   -- Black Friday spike
        WHEN MOD(seq.n, 8) = 1 THEN 20231125
        WHEN MOD(seq.n, 7) = 0 THEN 20240101
        ELSE DATE_FORMAT(DATE_ADD('2023-01-01', INTERVAL MOD(seq.n * 7, 730) DAY), '%Y%m%d') + 0
    END                                             AS order_date_key,
    ELT(MOD(seq.n, 10) + 1,
        'delivered','delivered','delivered','delivered',
        'delivered','delivered','shipped',
        'returned','cancelled','delivered')          AS order_status,
    ELT(MOD(seq.n, 4) + 1, 'web','web','mobile_app','marketplace') AS channel,
    ROUND(pr.unit_price * (1 + MOD(seq.n, 3)), 2)  AS subtotal,
    IF(MOD(seq.n,3)=0, ROUND(pr.unit_price*0.15,2), 0.00) AS discount_amount,
    IF(pr.unit_price * (1+MOD(seq.n,3)) >= 75, 0.00, 7.99) AS shipping_fee,
    ROUND(pr.unit_price * (1+MOD(seq.n,3)) * 0.08, 2)     AS tax_amount,
    1 + MOD(seq.n, 3)                               AS item_count,
    IF(seq.n <= 20, 1, 0)                           AS is_first_order
FROM
    -- Number sequence 1..300 (generates 300 orders)
    (SELECT ones.n + tens.n * 10 + hundreds.n * 100 + 1 AS n
     FROM
        (SELECT 0 n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4
         UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) ones
     CROSS JOIN
        (SELECT 0 n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4
         UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) tens
     CROSS JOIN
        (SELECT 0 n UNION SELECT 1 UNION SELECT 2) hundreds
    ) seq
-- Rotate through customers
JOIN (SELECT customer_sk, ROW_NUMBER() OVER (ORDER BY customer_sk) AS rn
      FROM dim_customers WHERE is_current = 1) c
  ON c.rn = MOD(seq.n, 20) + 1
-- Rotate through products (for subtotal base price)
JOIN (SELECT unit_price, ROW_NUMBER() OVER (ORDER BY product_sk) AS rn
      FROM dim_products) pr
  ON pr.rn = MOD(seq.n, 20) + 1
-- Rotate through promos
JOIN (SELECT promo_sk, ROW_NUMBER() OVER (ORDER BY promo_sk) AS rn
      FROM dim_promotions) p
  ON p.rn = MOD(seq.n, 10) + 1
WHERE seq.n <= 300;

-- ── 5. Order Items (one item per order, fast bulk insert) ─
INSERT INTO fact_order_items
    (order_sk, order_id, product_sk, quantity, unit_price, unit_cost, line_discount)
SELECT
    fo.order_sk,
    fo.order_id,
    pr.product_sk,
    fo.item_count                   AS quantity,
    pr.unit_price,
    pr.unit_cost,
    0.0000                          AS line_discount
FROM fact_orders fo
JOIN (SELECT product_sk, unit_price, unit_cost,
             ROW_NUMBER() OVER (ORDER BY product_sk) AS rn
      FROM dim_products) pr
  ON pr.rn = MOD(fo.order_sk, 20) + 1;

-- ── 6. Final row count check ──────────────────────────────
SELECT 'dim_date'          AS table_name, COUNT(*) AS row_count FROM dim_date
UNION ALL SELECT 'dim_customers',          COUNT(*) FROM dim_customers
UNION ALL SELECT 'dim_products',           COUNT(*) FROM dim_products
UNION ALL SELECT 'dim_promotions',         COUNT(*) FROM dim_promotions
UNION ALL SELECT 'fact_orders',            COUNT(*) FROM fact_orders
UNION ALL SELECT 'fact_order_items',       COUNT(*) FROM fact_order_items;
