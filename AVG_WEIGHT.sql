WITH dates AS (
----change the start and end date to recent 3 months
  SELECT DATE(CURRENT_DATE()- INTERVAL 12 WEEK) AS start_date,
    DATE(CURRENT_DATE()) AS end_date)

,totalSales AS(
  SELECT 
    artcl_num AS article_number,
    SUM(prrtd_pstd_sl_qty) AS TotalSaleQuantity,
    SUM(tlog_sl_wgt) AS TotalSaleWeight
  FROM `lt-dia-lake-prd-consume.financial_reporting.sales_lcl_store_article_dly` T
    ,dates D
  WHERE trans_dt >= start_date
  GROUP BY 1
)

SELECT 
t.article_number,
p.liam,
t.article_desc_english,
CASE -- new avg weight 
  WHEN TotalSaleWeight =  0 THEN ROUND(attributes.estimated_typical_weight,3) -- if there is no TotalSaleWeight in last 3 months, we keep old_avg_weight 
  WHEN TotalSaleQuantity <> 0 THEN ROUND(SAFE_DIVIDE(TotalSaleWeight,TotalSaleQuantity),3) 
  WHEN TotalSaleQuantity =  0 THEN ROUND(attributes.estimated_typical_weight,3) -- if there is no sales in last 3 months, we keep old_avg_weight 
  ELSE ROUND(attributes.estimated_typical_weight,3)
  END AS new_avg_weight, 
ROUND(attributes.estimated_typical_weight,3) as old_avg_weight, 
TotalSaleQuantity
TotalSaleWeight, 
CASE -- diff_avg_weight
  WHEN TotalSaleQuantity <> 0 THEN ROUND(SAFE_SUBTRACT(SAFE_DIVIDE(TotalSaleWeight,TotalSaleQuantity),attributes.estimated_typical_weight),3) 
  WHEN TotalSaleQuantity =  0 THEN 0 -- there is no sales in last 3 months to compare
  ELSE 0
  END AS diff_avg_weight,
t.mch_3_desc_english aS mch_3,
p.uom,
attributes.sold_by_uom as sold_by_uom,      
attributes.additional_comparison_unit,      
attributes.additional_comparison_uom,     
attributes.sold_by_incr,    
attributes.sold_by_unit,
-- 1 means change needed, 0 is correct
CASE WHEN attributes.sold_by_uom = 'EA'THEN 0 ELSE 1 END AS uom_check, -- and attributes.sold_by_uom = 'EA' 
CASE WHEN attributes.sold_by_incr = 1 THEN 0 ELSE 1 END AS sold_by_incr_check,-- and attributes.sold_by_incr = 1
CASE WHEN attributes.sold_by_unit  =1 THEN 0 ELSE 1 END AS sold_by_unit_check,-- and attributes.sold_by_unit  =1
CASE WHEN attributes.additional_comparison_unit = 1 THEN 0 ELSE 1 END AS additional_comparison_unit_check, -- and attributes.additional_comparison_unit = 1     
CASE WHEN attributes.additional_comparison_uom = 'LB'THEN 0 ELSE 1 END AS additional_comparison_uom_check -- and attributes.additional_comparison_uom = 'LB'     
FROM `ld-ds-bi-analytics-prod.bi_reporting.pcx_teradata_articles` t 
  JOIN `ld-ds-bi-analytics-prod.product_catalog.products` p on p.article_number = t.article_number 
  JOIN totalSales s on s.article_number = p.article_number
WHERE t.mch_3_code in ('M03','M11') and t.mch_3_desc_english in ('Meat','Seafood') 
  and p.uom = 'KG'
  and p.status = 'APPROVED'