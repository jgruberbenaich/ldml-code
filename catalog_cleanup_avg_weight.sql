 WITH

pt AS (
  SELECT CONCAT(artcl_num,"_KG") AS liam, 
    artcl_med_desc_en AS sap_name, 
    mch_3_desc_en AS mch_3, 
    mch_2_desc_en AS mch_2, 
    mch_1_desc_en AS mch_1, 
    mch_0_desc_en AS mch_0, 
    mch_0_cd,
    attributes.sold_by_uom,
    attributes.comparison_unit,
    attributes.comparison_uom,
    attributes.additional_comparison_unit,
    attributes.additional_comparison_uom,
    attributes.estimated_typical_weight
  FROM `lt-dia-lake-prd-consume.product.article_curr`
  JOIN `ld-ds-bi-analytics-prod.product_catalog.products` ON artcl_num = article_number
  WHERE status = "APPROVED"
    AND liam LIKE "2%"
    AND uom = "KG" 
    AND UPPER(IFNULL(attributes.sold_by_uom,'')) NOT IN ('ML','KG','G') -- For now only consider items that SHOULD have an average weight (i.e. sold by each, priced by weight)
    AND (mch_3_cd IN ('M03','M11') -- Meat & Seafood
      OR mch_2_cd = 'M0228') -- Produce Salad Bar
  ), 
  
sales AS (
  SELECT CONCAT(artcl_num,"_",sl_uom_cd) AS liam,
    prrtd_pstd_sl_amt,
    prrtd_pstd_sl_qty,
    tlog_sl_qty,
    tlog_sl_wgt,
    tlog_scan_qty,
    ROUND(SAFE_DIVIDE(tlog_sl_qty,tlog_scan_qty),3) AS unit_wt,
    PERCENT_RANK() OVER (PARTITION BY CONCAT(artcl_num,"_",sl_uom_cd) ORDER BY ROUND(SAFE_DIVIDE(tlog_sl_wgt,tlog_scan_qty),3)) AS unit_wt_rank
  FROM `lt-dia-lake-prd-consume.financial_reporting.sales_lcl_store_article_dly`
  WHERE trans_dt >= CURRENT_DATE()-84
    AND artcl_acct_assn_grp_cd IN ('01','21')
),

median AS (
  SELECT DISTINCT liam,
  PERCENTILE_CONT(ROUND(unit_wt,3), 0.5) OVER(PARTITION BY liam) AS median_wt
  FROM sales
)

SELECT pt.*,
  SUM(prrtd_pstd_sl_amt) AS L12W_sales,
  SUM(prrtd_pstd_sl_qty) AS L12W_qty,
  SUM(tlog_sl_qty) AS L12W_tlog_qty,
  SUM(tlog_sl_wgt) AS L12W_weight,
  SUM(tlog_scan_qty) AS L12W_scans,
  ROUND(AVG(unit_wt),3) AS L12W_mean_wt,
  1-SAFE_DIVIDE(ROUND(AVG(unit_wt),3),estimated_typical_weight) AS L12W_mean_delta,
  ROUND(AVG(IF(unit_wt_rank BETWEEN 0.1 AND 0.9,unit_wt,NULL)),3) AS L12W_mean_mid80_wt,
  1-SAFE_DIVIDE( ROUND(AVG(IF(unit_wt_rank BETWEEN 0.1 AND 0.9,unit_wt,NULL)),3),estimated_typical_weight) AS mean_mid80_delta,
  APPROX_QUANTILES(unit_wt, 100)[OFFSET(50)] AS appx_median_wt,
  1-SAFE_DIVIDE(APPROX_QUANTILES(unit_wt, 100)[OFFSET(50)],estimated_typical_weight) AS appx_median_delta,
  ROUND(median_wt,3) AS median_wt,
  1-SAFE_DIVIDE(ROUND(median_wt,3),estimated_typical_weight) AS median_delta,
FROM pt
JOIN sales ON pt.liam = sales.liam
JOIN median ON sales.liam = median.liam
GROUP BY ALL