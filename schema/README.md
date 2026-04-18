# 🛒 E-Commerce Data Warehouse — SQL Portfolio Project

A production-style data warehouse built in **MySQL 8+** for an e-commerce platform.  
Demonstrates dimensional modeling, ETL design patterns, and advanced analytics.

---

## 🚀 Quick Setup (Step by Step)

### Step 1 — Open MySQL Workbench
Open MySQL Workbench and connect to your local MySQL server.  
(Usually "Local instance 3306" on the home screen.)

### Step 2 — Open the first SQL file
- Go to **File → Open SQL Script**
- Select `01_schema.sql`
- Press **Ctrl + Shift + Enter** (runs the whole file)
- You should see `730 calendar_rows_created` in the results

### Step 3 — Run the seed data
- Go to **File → Open SQL Script**
- Select `02_seed_data.sql`
- Press **Ctrl + Shift + Enter**
- Wait ~30 seconds (it generates 2,000 orders)
- You'll see a row count table at the end confirming the data loaded

### Step 4 — Run your first analytics query
- Open `03_analytics.sql`
- **Select just one query** (click at the start, drag to the end)
- Press **Ctrl + Shift + Enter**

> **Tip:** You can run individual queries by placing your cursor anywhere inside  
> the query and pressing **Ctrl + Enter**

---

## 📐 What Was Built

```
Raw Data (JSON) → Staging → Warehouse → Analytics
```

### Database: `ecommerce_dw`

| Table | Type | Description |
|-------|------|-------------|
| `dim_date` | Dimension | Calendar table with 730 days (2023–2024) |
| `dim_customers` | Dimension (SCD2) | 30 customers with tier-upgrade history |
| `dim_products` | Dimension | 20 products across 4 categories |
| `dim_promotions` | Dimension | 10 promotional discount codes |
| `fact_orders` | Fact | ~2,000 orders with real financial math |
| `fact_order_items` | Fact | Individual line items per order |

---

## 📊 Analytics Queries Included

| # | Query | Business Question Answered |
|---|-------|---------------------------|
| 1 | Monthly Revenue + MoM Growth | "Is revenue trending up?" |
| 2 | Cohort Retention Matrix | "Do customers come back?" |
| 3 | RFM Customer Segmentation | "Who are our best customers?" |
| 4 | Top 3 Products Per Category | "What sells best in each category?" |
| 5 | Promo Code Effectiveness | "Are our discounts worth it?" |
| 6 | Geographic Revenue (YoY) | "Which states are growing?" |
| 7 | Pareto Revenue Analysis | "Do 20% of days drive 80% of sales?" |
| 8 | Data Quality / ETL Audit | "Is our data clean?" |

---

## 🔑 Key Concepts Demonstrated

**Dimensional Modeling (Kimball Star Schema)**  
Fact tables at the center, dimensions around them. Optimized for analytical queries.

**SCD Type 2 (Slowly Changing Dimensions)**  
`dim_customers` tracks when customers change tiers over time — so historical orders are attributed to the correct tier *at the time of purchase*, not the current one.

**Generated / Computed Columns**  
`total_amount`, `line_revenue`, and `gross_margin` are calculated automatically by MySQL — no transformation bugs possible.

**Stored Procedure for ETL**  
`generate_orders()` mimics a real data pipeline: it loops through records, applies business logic (promo discounts, free shipping thresholds, tax), and inserts consistently.

**Window Functions**  
LAG, LEAD, NTILE, DENSE_RANK, SUM OVER — all used in the analytics queries.

---

## ⚙️ Requirements

- MySQL 8.0 or higher (window functions require v8+)
- MySQL Workbench (any recent version)

---

## 🗂️ Files

```
01_schema.sql     → Create database + all tables + dim_date population
02_seed_data.sql  → Insert products, customers, promotions + generate orders
03_analytics.sql  → 8 analytical queries (run individually)
```

---

## 💡 How to Explain This Project in an Interview

**"What did you build?"**  
> "A Kimball-style star schema data warehouse for an e-commerce platform — staging, warehouse, and mart layers — with fact/dimension tables, SCD2 customer history, and computed columns for financial metrics."

**"What advanced SQL did you use?"**  
> "Window functions including LAG for MoM growth, NTILE for RFM scoring, DENSE_RANK for category rankings, and cumulative SUM OVER for Pareto analysis."

**"Why did you use a stored procedure for seeding?"**  
> "To simulate an ETL pipeline with realistic business logic — variable promo discounts, conditional shipping fees, and tax — the same pattern you'd use in a real ingestion job."
