-- ============================================================
--  STEP 1: CREATE THE DATABASE
--  Run this first, then select it before running anything else
-- ============================================================

CREATE DATABASE IF NOT EXISTS ecommerce_dw;
USE ecommerce_dw;

-- ============================================================
--  DIMENSION TABLES  (lookup / reference data)
-- ============================================================

-- ── dim_date: one row per calendar day ────────────────────
-- This table is the backbone of all time-based analysis
CREATE TABLE IF NOT EXISTS dim_date (
    date_key        INT          NOT NULL PRIMARY KEY,  -- format: YYYYMMDD e.g. 20240115
    full_date       DATE         NOT NULL UNIQUE,
    year            SMALLINT     NOT NULL,
    quarter         TINYINT      NOT NULL,
    month           TINYINT      NOT NULL,
    month_name      VARCHAR(10)  NOT NULL,
    week_of_year    TINYINT      NOT NULL,
    day_of_month    TINYINT      NOT NULL,
    day_of_week     TINYINT      NOT NULL,               -- 1=Monday … 7=Sunday
    day_name        VARCHAR(10)  NOT NULL,
    is_weekend      TINYINT(1)   NOT NULL DEFAULT 0,
    fiscal_year     SMALLINT     NOT NULL                -- Feb–Jan fiscal calendar
);

-- ── dim_customers: who bought from us ─────────────────────
-- SCD Type 2: keeps history when a customer changes tier
-- (e.g. Standard → Gold). Old row gets end-dated, new row inserted.
CREATE TABLE IF NOT EXISTS dim_customers (
    customer_sk     INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,  -- surrogate (warehouse) key
    customer_id     VARCHAR(36)  NOT NULL,                              -- natural (source system) key
    email           VARCHAR(255) NOT NULL,
    first_name      VARCHAR(100),
    last_name       VARCHAR(100),
    city            VARCHAR(100),
    state_code      CHAR(2),
    customer_tier   VARCHAR(20)  NOT NULL DEFAULT 'standard',
                    -- standard → silver → gold → vip
    acquisition_channel VARCHAR(50),
    effective_from  DATE         NOT NULL,
    effective_to    DATE         NOT NULL DEFAULT '9999-12-31',
    is_current      TINYINT(1)   NOT NULL DEFAULT 1,
    created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_customer_id   (customer_id),
    INDEX idx_current       (customer_id, is_current),
    INDEX idx_email         (email)
);

-- ── dim_products: what we sell ────────────────────────────
CREATE TABLE IF NOT EXISTS dim_products (
    product_sk      INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
    product_id      VARCHAR(36)  NOT NULL UNIQUE,
    sku             VARCHAR(100) NOT NULL UNIQUE,
    product_name    VARCHAR(255) NOT NULL,
    category        VARCHAR(100) NOT NULL,
    subcategory     VARCHAR(100),
    brand           VARCHAR(100),
    unit_cost       DECIMAL(12,4) NOT NULL,
    unit_price      DECIMAL(12,4) NOT NULL,
    is_active       TINYINT(1)   NOT NULL DEFAULT 1,
    launched_on     DATE,
    INDEX idx_category (category)
);

-- ── dim_promotions: discount codes ────────────────────────
CREATE TABLE IF NOT EXISTS dim_promotions (
    promo_sk        INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
    promo_code      VARCHAR(50)  NOT NULL UNIQUE,
    promo_name      VARCHAR(255) NOT NULL,
    promo_type      VARCHAR(30)  NOT NULL,
                    -- 'percentage' | 'flat' | 'free_shipping'
    discount_value  DECIMAL(8,4) NOT NULL,
    min_order_value DECIMAL(12,2),
    starts_at       DATE         NOT NULL,
    ends_at         DATE         NOT NULL
);

-- ============================================================
--  FACT TABLES  (transactional data — the big tables)
-- ============================================================

-- ── fact_orders: one row per order ────────────────────────
CREATE TABLE IF NOT EXISTS fact_orders (
    order_sk            INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
    order_id            VARCHAR(36)  NOT NULL UNIQUE,
    customer_sk         INT          NOT NULL,
    promo_sk            INT,                             -- nullable (not all orders have promos)
    order_date_key      INT          NOT NULL,
    order_status        VARCHAR(30)  NOT NULL,
                        -- pending | confirmed | shipped | delivered | returned | cancelled
    channel             VARCHAR(30)  NOT NULL,
                        -- web | mobile_app | marketplace | in_store
    subtotal            DECIMAL(14,2) NOT NULL,
    discount_amount     DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    shipping_fee        DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    tax_amount          DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    total_amount        DECIMAL(14,2) AS                -- computed column
                        (subtotal - discount_amount + shipping_fee + tax_amount)
                        STORED,
    item_count          TINYINT      NOT NULL DEFAULT 1,
    is_first_order      TINYINT(1)   NOT NULL DEFAULT 0,
    created_at          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_sk)    REFERENCES dim_customers (customer_sk),
    FOREIGN KEY (promo_sk)       REFERENCES dim_promotions (promo_sk),
    FOREIGN KEY (order_date_key) REFERENCES dim_date (date_key),
    INDEX idx_customer  (customer_sk, order_date_key),
    INDEX idx_status    (order_status),
    INDEX idx_date      (order_date_key)
);

-- ── fact_order_items: one row per product per order ───────
CREATE TABLE IF NOT EXISTS fact_order_items (
    item_sk         INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
    order_sk        INT          NOT NULL,
    order_id        VARCHAR(36)  NOT NULL,
    product_sk      INT          NOT NULL,
    quantity        SMALLINT     NOT NULL,
    unit_price      DECIMAL(12,4) NOT NULL,
    unit_cost       DECIMAL(12,4) NOT NULL,
    line_discount   DECIMAL(12,4) NOT NULL DEFAULT 0.0000,
    line_revenue    DECIMAL(14,2) AS
                    ((unit_price - line_discount) * quantity) STORED,
    line_cost       DECIMAL(14,2) AS
                    (unit_cost * quantity) STORED,
    gross_margin    DECIMAL(14,2) AS
                    ((unit_price - line_discount - unit_cost) * quantity) STORED,
    is_returned     TINYINT(1)   NOT NULL DEFAULT 0,
    FOREIGN KEY (order_sk)   REFERENCES fact_orders   (order_sk),
    FOREIGN KEY (product_sk) REFERENCES dim_products  (product_sk),
    INDEX idx_order   (order_sk),
    INDEX idx_product (product_sk)
);

-- ============================================================
--  HELPER: procedure to populate dim_date
-- ============================================================

DROP PROCEDURE IF EXISTS populate_dim_date;

DELIMITER $$
CREATE PROCEDURE populate_dim_date(
    IN p_start DATE,
    IN p_end   DATE
)
BEGIN
    DECLARE v_date DATE DEFAULT p_start;
    DECLARE v_key  INT;

    WHILE v_date <= p_end DO
        SET v_key = YEAR(v_date) * 10000
                  + MONTH(v_date) * 100
                  + DAY(v_date);

        INSERT IGNORE INTO dim_date (
            date_key, full_date, year, quarter, month, month_name,
            week_of_year, day_of_month, day_of_week, day_name,
            is_weekend, fiscal_year
        )
        VALUES (
            v_key,
            v_date,
            YEAR(v_date),
            QUARTER(v_date),
            MONTH(v_date),
            MONTHNAME(v_date),
            WEEK(v_date, 3),
            DAY(v_date),
            -- DAYOFWEEK: 1=Sun so we shift to 1=Mon
            IF(DAYOFWEEK(v_date) = 1, 7, DAYOFWEEK(v_date) - 1),
            DAYNAME(v_date),
            IF(DAYOFWEEK(v_date) IN (1,7), 1, 0),
            -- Fiscal year starts Feb 1
            IF(MONTH(v_date) >= 2, YEAR(v_date), YEAR(v_date) - 1)
        );

        SET v_date = DATE_ADD(v_date, INTERVAL 1 DAY);
    END WHILE;
END$$
DELIMITER ;

-- Run the date population
CALL populate_dim_date('2023-01-01', '2024-12-31');

SELECT COUNT(*) AS calendar_rows_created FROM dim_date;
