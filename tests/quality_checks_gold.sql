/*
===============================================================================
Quality Checks
===============================================================================
Script Purpose:
    Validates the integrity, consistency, and accuracy of the Gold Layer.

Checks include:
    - Uniqueness of surrogate keys
    - Referential integrity between fact and dimensions
===============================================================================
*/

-- ====================================================================
-- Checking 'gold.dim_customers'
-- ====================================================================

-- Check uniqueness of customer_key
-- Expectation: No results
SELECT 
    customer_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;



-- ====================================================================
-- Checking 'gold.dim_products'
-- ====================================================================

-- Check uniqueness of product_key
-- Expectation: No results
SELECT 
    product_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;



-- ====================================================================
-- Checking 'gold.fact_sales'
-- ====================================================================

-- Validate referential integrity between fact and dimensions
-- Expectation: No results

SELECT 
    f.order_number,
    f.customer_key,
    f.product_key
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON c.customer_key = f.customer_key
LEFT JOIN gold.dim_products p
    ON p.product_key = f.product_key
WHERE c.customer_key IS NULL
   OR p.product_key IS NULL;



-- ============================================
-- Compare this value to total number of sales
-- ============================================

SELECT COUNT(*) AS fact_rows
FROM gold.fact_sales;