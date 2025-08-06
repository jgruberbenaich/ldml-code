-- Josh's ask
-- Prepared In Canada Tagged Items Sales

WITH

dt AS (
  SELECT cal_date, 
    CASE 
      WHEN cal_date >= '2025-02-06' THEN "post-badge"
      WHEN cal_date < '2025-02-06' THEN "pre-badge"
      END AS timeframe
  FROM `ld-pcx-bia.dim.dates`
  WHERE cal_date BETWEEN '2025-02-06' AND '2025-02-10'
    OR cal_date BETWEEN '2025-01-30' AND '2025-02-03'
  ORDER BY 1 DESC
  ), 

st AS (
  -- details for all pcx-enabled stores active between start of relevant period and today
  SELECT DISTINCT 
    LPAD(hub_store_number,4,'0') AS store_number,
    division, 
    banner_name AS banner,
  FROM `ld-pcx-bia.dim.stores_flip`
  WHERE 1=1
    AND active_date <= CURRENT_DATE()
    AND LENGTH(store_number) <= 4
    AND division NOT IN ('Other') -- Exclude JF, RCLS
  ),


pt AS (
  SELECT liam
  FROM `ld-ds-bi-analytics-prod.product_catalog.products`
  WHERE article_number LIKE "2%"
    AND status = "APPROVED"
    AND LOWER(ARRAY_TO_STRING(tags,',')) LIKE "%prepared_in_canada%"  
),

og_sales AS (
  SELECT
    CONCAT(article_id,"_",og.sales_uom_cd) AS liam,
    transaction_dt AS cal_date,
    LPAD(site_id,4,'0') AS store_number,
    SUM(sales_amt) AS og_sales,
    SUM(sales_qty) AS og_qty,
    SUM(gp_amt) AS og_margin,
    AVG(prorated_pstd_ut_gp_cost_amt) AS og_unit_cost,
    SUM(CASE WHEN fulfillment_type = "PCX Pickup" THEN sales_amt ELSE 0 END) AS pcx_pickup_sales,
    SUM(CASE WHEN fulfillment_type = "PCX Delivery" THEN sales_amt ELSE 0 END) AS pcx_delivery_sales,
    SUM(CASE WHEN fulfillment_type = "Instacart" THEN sales_amt ELSE 0 END) AS instacart_sales,
    SUM(CASE WHEN fulfillment_type = "DD Marketplace" THEN sales_amt ELSE 0 END) AS doordash_sales,
    SUM(CASE WHEN fulfillment_type = 'PCX Pick & Deliver' THEN sales_amt ELSE 0 END) AS pick_deliver_sales
  FROM `ld-ds-bi-analytics-prod.bi_reporting.sl_trans_qlfy_ecom_dly` og -- ecom transactions
    JOIN dt ON og.transaction_dt = dt.cal_date -- dates specified above
    JOIN st ON LPAD(og.site_id,4,'0') = st.store_number -- stores specified above
    JOIN pt ON liam = CONCAT(article_id,"_",og.sales_uom_cd)
  WHERE transaction_dt >= '2025-01-30'
    AND article_id LIKE "2%"
    AND article_acct_assn_grp_cd IN ('01','21') -- Always use this filter on ecom
    AND fulfillment_type IN ('PCX Delivery','PCX Pickup','Instacart','DD Marketplace','PCX Pick & Deliver') -- Exclude JFSFS and LD-Marketplace
  GROUP BY ALL
),

rtl_sales AS (
  SELECT
    CONCAT(artcl_num,"_",sl_uom_cd) AS liam,
    trans_dt AS cal_date,
    LPAD(site_num,4,'0') AS store_number,
    SUM(prrtd_pstd_sl_amt) AS rtl_sales,
    SUM(prrtd_pstd_sl_qty) AS rtl_qty
  FROM `lt-dia-lake-prd-consume.financial_reporting.sales_lcl_store_article_dly` rtl -- instore + online transactions
    JOIN dt ON rtl.trans_dt = dt.cal_date -- dates specified above
    JOIN st ON LPAD(rtl.site_num,4,'0') = st.store_number -- stores specified above
    JOIN pt ON liam = CONCAT(artcl_num,"_",sl_uom_cd)
  WHERE trans_dt >= '2025-01-30'
    AND artcl_num LIKE "2%"
    AND artcl_acct_assn_grp_cd IN ('01','21') -- Always use this filter on ecom
  GROUP BY ALL
),

sales_data AS (
  SELECT *
  FROM og_sales
  FULL JOIN rtl_sales USING(liam, store_number, cal_date)
)

SELECT cal_date, 
  SUM(pcx_pickup_sales) AS pcx_pickup, 
  SUM(pcx_delivery_sales) AS pcx_delivery, 
  SUM(rtl_sales) AS total_sales
FROM sales_data
GROUP BY ALL