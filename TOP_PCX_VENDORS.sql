WITH 
dates AS (
  SELECT 
  "2023-01-01" AS start_date, -- update to the beginning of the timeframe you want to check
  "2023-12-31" AS end_date -- update to the end of the timeframe you want to check
),

suppliers AS (
  SELECT artcl_num,
    IFNULL(rolodex_name, vend_nm) AS supplier,
    rolodex_name IS NOT NULL AS is_recipient,
  FROM `ld-ds-bi-analytics-prod.bi_dw.vendor_determination` vd
    LEFT JOIN `ld-pcx-bia.Merch_PIM.SUPPLIER_ROLODEX` ON vend_num = VENDOR_NUMBER
    LEFT JOIN `ld-pcx-bia.Merch_PIM.SUPPLIER_SCORECARD_EXCLUSIONS` x ON LTRIM(x.vendor_number,'0') = LTRIM(vd.vend_num,'0') 
    AND x.article_number = vd.artcl_num
  WHERE x.article_number IS NULL -- Exclude known mistakes from vendor table
),

supplier_articles AS (
  SELECT supplier, is_recipient,
    artcl_num,
    artcl_med_desc_en AS sap_name,
    RANK() OVER (PARTITION BY supplier ORDER BY SUM(prrtd_pstd_sl_amt) DESC) AS supplier_article_rank,
    SUM(prrtd_pstd_sl_amt) AS article_sales,
    SUM(prrtd_pstd_sl_qty) AS article_qty
  FROM `lt-dia-lake-prd-consume.financial_reporting.sales_lcl_store_article_dly`
  JOIN `lt-dia-lake-prd-consume.product.article_curr` USING (artcl_num)
  JOIN suppliers USING(artcl_num)
  ,dates
  WHERE trans_dt BETWEEN DATE(start_date) AND DATE(end_date) -- REQUIRED TO put a trans_dt filter
    AND artcl_acct_assn_grp_cd IN ('01','21') -- ALWAYS use this filter on this table
    AND brnd_ty_cd = '2'
  GROUP BY 1,2,3,4
  )

SELECT supplier, is_recipient,
  SUM(article_sales) AS total_sales,
  SUM(article_qty) AS total_qty,
  COUNT(DISTINCT artcl_num) AS articles,
  MIN_BY(artcl_num,supplier_article_rank) AS top_article_num
FROM supplier_articles
GROUP BY 1,2
ORDER BY total_sales DESC
