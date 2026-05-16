CREATE DATABASE ecommerce_portfolio;
USE ecommerce_portfolio;

-- ====================================================================
-- PORTFOLIO QUERY: CUSTOMER LIFETIME VALUE & GEOGRAPHIC PROFIT MARGINS
-- ====================================================================

WITH Customer_Metrics AS (
    -- Step 1: Aggregate order data per customer using CTE
    SELECT 
        customer_id,
        COUNT(order_id) AS total_orders,
        SUM(sales_amount) AS total_spent,
        SUM(profit_amount) AS total_profit,
        MAX(order_date) AS last_purchase_date
    FROM fact_orders
    WHERE delivery_status != 'Cancelled' -- Exclude cancelled orders from financial KPIs
    GROUP BY customer_id
),
Regional_Analysis AS (
    -- Step 2: Combine aggregates with customer attributes and calculate margins
    SELECT 
        c.customer_id,
        c.country,
        c.account_type,
        c.churn_risk_score,
        cm.total_orders,
        cm.total_spent,
        cm.total_profit,
        ROUND((cm.total_profit / cm.total_spent) * 100, 2) AS profit_margin_pct
    FROM dim_customers c
    JOIN Customer_Metrics cm ON c.customer_id = cm.customer_id
)
-- Step 3: Use Window Functions to rank customers by profitability within their country
SELECT 
    country,
    customer_id,
    account_type,
    total_spent AS lifetime_value_ltv,
    profit_margin_pct,
    churn_risk_score,
    DENSE_RANK() OVER (PARTITION BY country ORDER BY total_spent DESC) AS customer_rank_in_country
FROM Regional_Analysis
ORDER BY country ASC, lifetime_value_ltv DESC;
