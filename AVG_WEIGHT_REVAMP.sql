-- Average Weight Data Source Comparison

WITH
products AS (
  SELECT liam, article_number, artcl_med_desc_en AS sap_name, mch_3_desc_en AS mch_3, mch_2_desc_en AS mch_2, mch_1_desc_en AS mch_1, mch_0_desc_en AS mch_0, mch_0_cd, attributes.sold_by_uom, attributes.comparison_unit, attributes.comparison_uom, attributes.additional_comparison_unit, attributes.additional_comparison_uom, attributes.estimated_typical_weight,
  FROM `ld-ds-bi-analytics-prod.product_catalog.products`
  JOIN `lt-dia-lake-prd-consume.product.article_curr` ON artcl_num = article_number
  JOIN `ld-pcx-bia.Merch_PIM.PCX_ACTIVE_ARTICLE_STORES` USING(article_number) -- active products only
  WHERE status = "APPROVED"
    AND liam LIKE "2%"
    AND mch_3_desc_en IN ('Meat','Seafood') -- For now only consider items that we SHOULD be updating the average weight for (i.e. don't change produce, bulk candy&nuts, deli cheese)
    AND uom = "KG" AND UPPER(attributes.sold_by_uom) NOT IN ('ML','KG','G') -- For now only consider items that SHOULD have an average weight (i.e. sold by each, priced by weight)
    AND total_stores > 10 -- Actively assorted to min. 10 stores
),

ecom AS (
  SELECT CONCAT(article_id,"_",sales_uom_cd) AS liam,
    SUM(sales_amt) AS ecom_sales,
    SUM(sales_wgt) AS ecom_wgt,
    SUM(scan_qty) AS ecom_scans,
    COUNT(DISTINCT ecom_ord_num) AS ecom_orders,
    ROUND(AVG(SAFE_DIVIDE(sales_wgt,scan_qty)),3) AS ecom_avgweight,
    CONCAT("Min: ", CAST(ROUND(MIN(SAFE_DIVIDE(sales_wgt,scan_qty)),3) AS STRING), 
        "\nMax: ", CAST(ROUND(MAX(SAFE_DIVIDE(sales_wgt,scan_qty)),3) AS STRING)) AS ecom_weight_range -- Min & Max weight per unit
  FROM `ld-ds-bi-analytics-prod.bi_reporting.sl_trans_qlfy_ecom_dly`
  WHERE transaction_dt > CURRENT_DATE()-84
    AND article_acct_assn_grp_cd IN ('01','21')
    AND ecom_ind NOT IN ('2','3') -- Exclude LD Marketplace, JF SFS
    AND CONCAT(article_id,"_",sales_uom_cd) IN (SELECT liam FROM products)
  GROUP BY ALL
),

rtl AS (
  SELECT CONCAT(artcl_num,"_",sl_uom_cd) AS liam,
    SUM(prrtd_pstd_sl_amt) AS rtl_sales,
    SUM(prrtd_pstd_sl_qty) AS rtl_qty,
    SUM(tlog_sl_qty) AS rtl_tlog_qty,
    SUM(tlog_sl_wgt) AS rtl_weight,
    SUM(tlog_scan_qty) AS rtl_scans,
    ROUND(AVG(SAFE_DIVIDE(tlog_sl_wgt,tlog_scan_qty)),3) AS rtl_avgweight,
    CONCAT("Min: ", CAST(ROUND(MIN(SAFE_DIVIDE(tlog_sl_wgt,tlog_scan_qty)),3) AS STRING), 
        "\nMax: ", CAST(ROUND(MAX(SAFE_DIVIDE(tlog_sl_wgt,tlog_scan_qty)),3) AS STRING)) AS rtl_weight_range -- Min & Max weight per unit
  FROM `lt-dia-lake-prd-consume.financial_reporting.sales_lcl_store_article_dly`
  WHERE trans_dt > CURRENT_DATE()-84
    AND artcl_acct_assn_grp_cd IN ('01','21')
    AND CONCAT(artcl_num,"_",sl_uom_cd) IN (SELECT liam FROM products)
  GROUP BY ALL
)

SELECT *,
  ROUND(SAFE_SUBTRACT(ecom_avgweight, estimated_typical_weight),3) AS ecom_delta,
  ROUND(SAFE_SUBTRACT(rtl_avgweight, estimated_typical_weight),3) AS rtl_delta,
  CASE 
    WHEN UPPER(sold_by_uom) IN ('ML','KG','G') THEN "Remove Avg Weight" -- Any soldbyuom variations besides these 3 should be included consider 'EA'
    -- Scenario for lower than qty threshold
    -- Scenario for lower than weight change threshold
    -- Scenario for ignoring based on MCH (e.g. produce, bulk nuts, deli cheese)
    WHEN estimated_typical_weight <> ROUND(estimated_typical_weight,3) THEN "Update to rounded"
    -- Scenario for comparison unit/uom
    -- Scenario for additional comparison unit/uom
    END AS scenario
FROM products
LEFT JOIN ecom USING(liam)
LEFT JOIN rtl USING(liam)
