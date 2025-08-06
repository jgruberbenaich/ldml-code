WITH

  dt AS (
    SELECT cal_date,
    FROM `ld-pcx-bia.dim.dates`
    WHERE 1=1
      AND cal_date >= '2025-04-01'
    ), 

  st AS (
    -- details for all pcx-enabled stores active between start of relevant period and today
    SELECT DISTINCT 
      LPAD(hub_store_number,4,'0') AS store_number,
      banner_name,
      division
    FROM `ld-pcx-bia.dim.stores_flip`
    WHERE 1=1
      AND active_date <= '2025-04-01'
      AND LENGTH(store_number) <= 4
      AND division NOT IN ('Other') -- Exclude JF, RCLS
    ),

  pcs AS (
    SELECT liam,
      article_number,
      brand.name_en AS brand_en,
      name_en AS pcx_title_en,
    FROM `ld-ds-bi-analytics-prod.product_catalog.products`
    WHERE status = 'APPROVED'
      AND liam LIKE "2%"
  ),  

  art AS (
    SELECT artcl_num, 
      artcl_med_desc_en AS sap_description,
      mch_3_desc_en AS mch_3,
      mch_2_desc_en AS mch_2,
      mch_1_desc_en AS mch_1,
      mch_0_desc_en AS mch_0,
      mch_0_cd,
    FROM `lt-dia-lake-prd-consume.product.article_curr`
    LEFT JOIN pcs ON artcl_num = article_number
    WHERE artcl_num LIKE "2%"
  ),

  ord AS (
    SELECT LPAD(store_number,4,'0') AS store_number,
      order_number,
      order_status,
      base_price,
      entry_number,
      product_code,
      number_of_units,
      last_modified_time
  FROM `ld-ds-bi-analytics-prod.fulfillment_events.Order`
  WHERE 1=1
    AND product_code LIKE "2%"
  QUALIFY ROW_NUMBER() OVER (PARTITION BY order_number, product_code, order_status ORDER BY last_modified_time ASC) = 1 -- Only show first record for each order/liam/status combination
  ),

  sales AS (
    SELECT transaction_dt AS cal_date,
      LPAD(site_id,4,'0') AS store_number,
      CONCAT(article_id,"_",sales_uom_cd) AS liam,
      article_id AS artcl_num,
      ecom_ord_num,
      fulfillment_type,
      sales_amt,
      sales_qty,
      sales_wgt
    FROM `ld-ds-bi-analytics-prod.bi_reporting.sl_trans_qlfy_ecom_dly`
    WHERE transaction_dt = DATE_SUB(CURRENT_DATE('US/Eastern'), INTERVAL 1 DAY)
      AND article_id LIKE "2%"
      AND article_acct_assn_grp_cd IN ('01','21') -- Always use this filter on ecom
      AND fulfillment_type IN ('PCX Delivery','PCX Pickup','Instacart','DD Marketplace','PCX Pick & Deliver') -- Exclude JFSFS and LD-Marketplace
  )

SELECT * 
FROM dt