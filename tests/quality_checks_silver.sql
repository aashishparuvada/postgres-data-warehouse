/*
===============================================================================
Quality Checks
===============================================================================
Script Purpose:
    Performs data quality validation checks on the 'silver' layer.

    Checks include:
    - Duplicate or NULL primary keys
    - Leading/trailing spaces
    - Data standardization
    - Invalid date ranges
    - Data consistency checks
===============================================================================
*/

-- ====================================================================
-- Checking 'silver.crm_cust_info'
-- ====================================================================

-- Duplicate or NULL primary keys
SELECT 
    cst_id,
    COUNT(*)
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- Leading / trailing spaces
SELECT 
    cst_key
FROM silver.crm_cust_info
WHERE cst_key <> BTRIM(cst_key);

-- Data standardization
SELECT DISTINCT
    cst_marital_status
FROM silver.crm_cust_info;



-- ====================================================================
-- Checking 'silver.crm_prd_info'
-- ====================================================================

-- Duplicate or NULL primary keys
SELECT 
    prd_id,
    COUNT(*)
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- Leading / trailing spaces
SELECT 
    prd_nm
FROM silver.crm_prd_info
WHERE prd_nm <> BTRIM(prd_nm);

-- Invalid or missing costs
SELECT 
    prd_cost
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- Data standardization
SELECT DISTINCT
    prd_line
FROM silver.crm_prd_info;

-- Invalid date ranges
SELECT *
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;



-- ====================================================================
-- Checking 'silver.crm_sales_details'
-- ====================================================================

-- Invalid raw integer dates
SELECT
    NULLIF(sls_due_dt,0) AS sls_due_dt
FROM bronze.crm_sales_details
WHERE sls_due_dt <= 0
   OR LENGTH(sls_due_dt::TEXT) <> 8
   OR sls_due_dt > 20500101
   OR sls_due_dt < 19000101;

-- Invalid order of dates
SELECT *
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt
   OR sls_order_dt > sls_due_dt;

-- Sales consistency check
SELECT DISTINCT
    sls_sales,
    sls_quantity,
    sls_price
FROM silver.crm_sales_details
WHERE sls_sales <> sls_quantity * sls_price
   OR sls_sales IS NULL
   OR sls_quantity IS NULL
   OR sls_price IS NULL
   OR sls_sales <= 0
   OR sls_quantity <= 0
   OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price;



-- ====================================================================
-- Checking 'silver.erp_cust_az12'
-- ====================================================================

-- Out-of-range birthdates
SELECT DISTINCT
    bdate
FROM silver.erp_cust_az12
WHERE bdate < DATE '1924-01-01'
   OR bdate > CURRENT_TIMESTAMP;

-- Gender standardization
SELECT DISTINCT
    gen
FROM silver.erp_cust_az12;



-- ====================================================================
-- Checking 'silver.erp_loc_a101'
-- ====================================================================

SELECT DISTINCT
    cntry
FROM silver.erp_loc_a101
ORDER BY cntry;



-- ====================================================================
-- Checking 'silver.erp_px_cat_g1v2'
-- ====================================================================

-- Leading/trailing spaces
SELECT *
FROM silver.erp_px_cat_g1v2
WHERE cat <> BTRIM(cat)
   OR subcat <> BTRIM(subcat)
   OR maintenance <> BTRIM(maintenance);

-- Standardization check
SELECT DISTINCT
    maintenance
FROM silver.erp_px_cat_g1v2;