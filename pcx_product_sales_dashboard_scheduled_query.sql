/*
2025-02-17
-Developer: Jonathan Gruber-benaich
-Scheduled query to update the table `ld-pcx-bia.Merch_PIM.product_sales_dashboard_tbl` with daily sales
-Run daily at 15:30 UTC (10:30 AM EST)
-Use an INSERT INTO query because the scheduled query function to append results to a scheduled query does not support clustered tables

2025-06-30
-Update - add columns for SKIP and UBEREATS fulfillment

2025-07-03
-Update - replace ecom table with corrected source to identify IC and DD more accurately
-Update - removed a redundant CTE from the query

2025-07-30
-Update - refer to retail cost instead of ecom cost to get more results. Divide by the sales qty units.
*/
---
INSERT INTO `ld-pcx-bia.Merch_PIM.product_sales_dashboard_tbl`

WITH

dt AS (
  SELECT cal_date,
  FROM `ld-pcx-bia.dim.dates`
  WHERE cal_date = DATE_SUB(CURRENT_DATE('US/Eastern'), INTERVAL 1 DAY)
  ORDER BY 1 DESC
  ), 

st AS (
  -- details for all pcx-enabled stores active between start of relevant period and today
  SELECT DISTINCT 
    LPAD(hub_store_number,4,'0') AS store_number,
  FROM `ld-pcx-bia.dim.stores_flip`
  WHERE 1=1
    AND active_date <= CURRENT_DATE('US/Eastern')
    AND LENGTH(store_number) <= 4
    AND division NOT IN ('Other') -- Exclude JF, RCLS

  ),

pt AS (
  SELECT 
    artcl_num AS article_number,
  FROM `lt-dia-lake-prd-consume.product.article_curr`
  WHERE artcl_num LIKE "2%"  
),

og_sales AS (
  SELECT
    CONCAT(article_id,"_",og.sales_uom_cd) AS liam,
    transaction_dt AS cal_date,
    LPAD(site_id,4,'0') AS store_number,
    SUM(sales_amt) AS og_sales,
    SUM(sales_qty) AS og_qty,
    SUM(gp_amt) AS og_margin,
    SUM(CASE WHEN fulfillment_type = "PCX Pickup" THEN sales_amt ELSE 0 END) AS pcx_pickup_sales,
    SUM(CASE WHEN fulfillment_type = "PCX Delivery" THEN sales_amt ELSE 0 END) AS pcx_delivery_sales,
    SUM(CASE WHEN fulfillment_type = "Instacart" THEN sales_amt ELSE 0 END) AS instacart_sales,
    SUM(CASE WHEN fulfillment_type = "DD Marketplace" THEN sales_amt ELSE 0 END) AS doordash_sales,
    SUM(CASE WHEN fulfillment_type = 'PCX Pick & Deliver' THEN sales_amt ELSE 0 END) AS pick_deliver_sales,
    SUM(CASE WHEN fulfillment_type = 'Skip the Dishes' THEN sales_amt ELSE 0 END) AS skip_sales,
    SUM(CASE WHEN fulfillment_type = 'Uber Eats' THEN sales_amt ELSE 0 END) AS ubereats_sales,
  FROM `ld-ds-bi-analytics-prod.bi_reporting.sl_trans_qlfy_ecom_dly_corrected` og -- ecom transactions
    JOIN dt ON og.transaction_dt = dt.cal_date -- dates specified above
    JOIN st ON LPAD(og.site_id,4,'0') = st.store_number -- stores specified above
    JOIN pt ON article_number = article_id
  WHERE transaction_dt = DATE_SUB(CURRENT_DATE('US/Eastern'), INTERVAL 1 DAY)
    AND article_id LIKE "2%"
    AND article_acct_assn_grp_cd IN ('01','21') -- Always use this filter on ecom
    AND ecom_ind NOT IN ('2','3') -- Exclude JFSFS and H&E-Marketplace
  GROUP BY ALL
),

rtl_sales AS (
  SELECT
    CONCAT(artcl_num,"_",sl_uom_cd) AS liam,
    trans_dt AS cal_date,
    LPAD(site_num,4,'0') AS store_number,
    SUM(prrtd_pstd_sl_amt) AS rtl_sales,
    SUM(prrtd_pstd_sl_qty) AS rtl_qty,
    SUM(prrtd_pstd_ext_gp_cost) AS rtl_cost
  FROM `lt-dia-lake-prd-consume.financial_reporting.sales_lcl_store_article_dly` rtl -- instore + online transactions
    JOIN dt ON rtl.trans_dt = dt.cal_date -- dates specified above
    JOIN st ON LPAD(rtl.site_num,4,'0') = st.store_number -- stores specified above
    JOIN pt ON rtl.artcl_num = article_number
  WHERE trans_dt = DATE_SUB(CURRENT_DATE('US/Eastern'), INTERVAL 1 DAY)
    AND artcl_num LIKE "2%"
    AND artcl_acct_assn_grp_cd IN ('01','21') -- Always use this filter on ecom
  GROUP BY ALL
),

order_data AS 
(
  SELECT cal_date, LPAD(hub_store_number,4,'0') AS store_number, item_number AS liam, 
      COUNT(DISTINCT(order_number)) AS order_count, 
      SUM(ordered_qty) AS ordered_qty,
      SUM(filled_qty) AS filled_qty, 
      SUM(subbed_qty) AS subbed_qty, 
      SUM(shorted_qty) AS shorted_qty
  FROM `ld-pcx-bia.ops.item_kpis` ops 
    JOIN dt on pickup_date = dt.cal_date
    JOIN st ON LPAD(ops.hub_store_number,4,'0') = st.store_number
    JOIN pt ON SPLIT(ops.item_number,"_")[OFFSET(0)] = pt.article_number
  WHERE pickup_date = DATE_SUB(CURRENT_DATE('US/Eastern'), INTERVAL 1 DAY)
    AND item_number LIKE "2%"
  GROUP BY ALL
),

asmnt_data AS 
(
  SELECT assortment_run_date AS cal_date, 
    LPAD(ao.store_number,4,'0') AS store_number, 
    article_uom AS liam, 
    1 AS pass_algo
  FROM `ld-ds-bi-analytics-prod.assortment.assortment_output` ao
    JOIN dt ON ao.assortment_run_date = dt.cal_date
    JOIN st ON LPAD(ao.store_number,4,'0') = st.store_number
    JOIN pt ON SPLIT(ao.article_uom,"_")[OFFSET(0)] = pt.article_number
  WHERE assortment_run_date = DATE_SUB(CURRENT_DATE('US/Eastern'), INTERVAL 1 DAY)
    AND article_uom LIKE "2%"
    AND passfail = "Pass"
  GROUP BY ALL
),

fj AS (
  SELECT *
  FROM og_sales
  FULL JOIN rtl_sales USING(liam, store_number, cal_date)
  FULL JOIN order_data USING(liam, store_number, cal_date)
  FULL JOIN asmnt_data USING(liam, store_number, cal_date)
)

SELECT DISTINCT
  liam,
  og_sales,
  og_qty,
  og_margin,
  rtl_cost,
  pcx_pickup_sales,
  pcx_delivery_sales,
  instacart_sales,
  doordash_sales,
  pick_deliver_sales,
  rtl_sales,
  rtl_qty,
  order_count,
  ordered_qty,
  filled_qty,
  subbed_qty,
  shorted_qty,
  pass_algo,
  cal_date,
  store_number,
  CURRENT_DATETIME('US/Eastern') AS run_datetime,
  skip_sales,
  ubereats_sales,
FROM fj
LEFT JOIN dt USING(cal_date)
LEFT JOIN st USING(store_number)
WHERE cal_date = DATE_SUB(CURRENT_DATE('US/Eastern'), INTERVAL 1 DAY)