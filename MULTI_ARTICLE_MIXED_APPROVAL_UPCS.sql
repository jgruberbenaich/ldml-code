WITH 
mean AS (-- All article UPCs
  SELECT CONCAT(LTRIM(matnr,'0'),"_",meinh) AS liam, ean11 AS UPC
  FROM `ld-ds-bi-analytics-prod.cerebro_reporting.sap_ecc_mean`
  WHERE DELETED_FLAG = FALSE
    AND LTRIM(matnr,'0') LIKE "2%" -- PCX articles
    AND hpean="X" -- primary upc for the liam
  ),

stores AS ( -- List of stores that are PCX enabled
  SELECT DISTINCT store_number,
    banner_name,store_division 
  FROM `ld-ds-bi-analytics-prod.bi_reporting.pcx_stores`
  WHERE LOWER(TRIM(banner_name)) NOT IN ('unknown','joe fresh','tt','real canadian liquor store')
    AND CHAR_LENGTH(store_number) <= 4
    AND og_close_date > CURRENT_DATE()
    AND active_date <= CURRENT_DATE()
),

rtl AS ( -- Liams which have enough sales in the relevant timeframe at PCX enabled stores
  SELECT UPC,
    CONCAT(artcl_num,"_",r.sl_uom_cd) AS liam, 
    artcl_num,
    artcl_med_desc_en AS sap_description,
    SUM(prrtd_pstd_sl_amt) AS total_sales_L12W
  FROM `lt-dia-lake-prd-consume.financial_reporting.sales_lcl_store_article_dly` r
  JOIN mean ON liam = CONCAT(artcl_num,"_",r.sl_uom_cd)
  JOIN stores ON LTRIM(store_number,'0') = LTRIM(site_num,'0')
  JOIN `lt-dia-lake-prd-consume.product.article_curr` USING(artcl_num)
  WHERE trans_dt > CURRENT_DATE()-84 -- Update to relevant # of previous days
    AND artcl_num LIKE "2%"
    AND artcl_acct_assn_grp_cd IN ('01','21')
    AND REGEXP_CONTAINS(r.sl_uom_cd, r'EA|KG|C\d') -- Valid selling uoms only (ea/KG/case)
  GROUP BY ALL
  HAVING total_sales_L12W > 1000 -- Update to relevant threshold
  ),

pcs AS (
  SELECT liam, 1 AS pcs_approved
  FROM `ld-ds-bi-analytics-prod.product_catalog.products`
  WHERE status = "APPROVED"
    AND liam LIKE "2%"
)

SELECT *
FROM rtl
LEFT JOIN pcs USING(liam)
QUALIFY SUM(pcs_approved) OVER(PARTITION BY upc) >=1 -- UPC has at least 1 liam approved in PCS 
  AND COUNTIF(rtl.liam NOT IN (SELECT liam FROM pcs)) OVER (PARTITION BY upc) >=1 -- UPC has at least 1 liam NOT approved in PCS
ORDER BY UPC, pcs_approved DESC, total_sales_L12W DESC
