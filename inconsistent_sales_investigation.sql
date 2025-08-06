SELECT 
  COUNT(*) AS records,
  COUNT(DISTINCT artcl_num) AS articles,
  SUM(prrtd_pstd_sl_amt) AS sales
  FROM `lt-dia-lake-prd-consume.financial_reporting.sales_lcl_store_article_dly`
  FOR SYSTEM_TIME AS OF TIMESTAMP("2024-11-25 14:45:21 UTC") -- Timestamp for problematic query +5 hours (UTC)
  WHERE trans_dt BETWEEN "2024-11-17" AND "2024-11-23" -- Previous Week
    AND LTRIM(site_num,'0') IN ('379','2800','2810') -- Relevant Stores Only
    AND artcl_acct_assn_grp_cd IN ('01','21') -- Always use this filter
  GROUP BY ALL