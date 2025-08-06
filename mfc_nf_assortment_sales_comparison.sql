WITH

dt AS 
  (SELECT DATE('2025-01-01') AS ytd_start, DATE('2025-06-30') AS ytd_end
  ),

st AS (
  SELECT * FROM UNNEST(['7154','6885','7509']) AS s -- REPLACE WITH RELEVANT NOFRILLS STORE NUMBER
  ),

pt AS (
  SELECT DISTINCT
    artcl_num,
    artcl_med_desc_en,
    mch_3_desc_en,
    mch_2_desc_en,
    mch_1_desc_en,
    mch_0_desc_en,
    mch_0_cd,
    ah_04_desc_en
  FROM `lt-dia-lake-prd-consume.product.article_curr`
  ),

ao AS (
  SELECT
    SPLIT(article_uom,"_")[SAFE_ORDINAL(1)] AS article,
    STRING_AGG(CASE WHEN store_number = '7154' THEN passfail_reason END) AS lob_mfc_algo,
    STRING_AGG(CASE WHEN store_number = '6885' THEN passfail_reason END) AS rcso_mfc_algo,
    STRING_AGG(CASE WHEN store_number = '7509' THEN passfail_reason END) AS nf_algo,
  FROM `ld-ds-bi-analytics-prod.assortment.assortment_output`
  WHERE assortment_run_date = CURRENT_DATE('EST')
    AND store_number IN (SELECT * FROM st)
  GROUP BY ALL
),

ecom AS (
  SELECT article_id,
    COUNT(DISTINCT CASE WHEN site_id IN ('6885','7154') THEN transaction_id END) AS mfc_orders,
    ROUND(SUM(CASE WHEN site_id IN ('6885','7154') THEN sales_amt END),2) AS mfc_sales,
    ROUND(SUM(CASE WHEN site_id IN ('6885','7154') THEN scan_qty END),2) AS mfc_units,
    ROUND(SUM(CASE WHEN site_id IN ('6885','7154') THEN gp_amt END),2) AS mfc_gp,
    COUNT(DISTINCT CASE WHEN site_id NOT IN ('6885','7154') THEN transaction_id END) AS nf_orders,
    ROUND(SUM(CASE WHEN site_id NOT IN ('6885','7154') THEN sales_amt END),2) AS nf_sales,
    ROUND(SUM(CASE WHEN site_id NOT IN ('6885','7154') THEN scan_qty END),2) AS nf_units,
    ROUND(SUM(CASE WHEN site_id NOT IN ('6885','7154') THEN gp_amt END),2) AS nf_gp
  FROM `ld-ds-bi-analytics-prod.bi_reporting.sl_trans_qlfy_ecom_dly_corrected`
  CROSS JOIN dt
  WHERE 1=1
    AND transaction_dt BETWEEN ytd_start AND ytd_end
    AND article_acct_assn_grp_cd IN ('01','21')
    AND site_id IN (SELECT * FROM st)
    AND fulfillment_type IN ('PCX Pickup', 'PCX Delivery')
  GROUP BY ALL
  )

SELECT 
  COALESCE(pt. artcl_num, ao.article, ecom.article_id) AS article_number,
  * EXCEPT(artcl_num, article, article_id),
  CASE WHEN nf_sales > 0 OR nf_algo LIKE "P%" THEN "Y" ELSE "N" END AS nf_match
FROM pt
FULL JOIN ao ON artcl_num = ao.article
FULL JOIN ecom ON artcl_num = article_id
WHERE mfc_sales > 0 OR lob_mfc_algo LIKE "P%" OR rcso_mfc_algo LIKE "P%"