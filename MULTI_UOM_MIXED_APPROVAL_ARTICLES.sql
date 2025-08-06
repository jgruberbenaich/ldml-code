WITH 
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
  SELECT CONCAT(artcl_num,"_",r.sl_uom_cd) AS liam, 
    artcl_num,
    artcl_med_desc_en AS sap_description,
    SUM(prrtd_pstd_sl_amt) AS total_sales_L12W
  FROM `lt-dia-lake-prd-consume.financial_reporting.sales_lcl_store_article_dly` r
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
  SELECT liam AS approved_liam, 
    article_number, 
    name_en, 
    name_fr, 
    description_en, 
    description_fr,
    attributes.items_per_package,
    attributes.item_size,
    attributes.item_size_uom,
    attributes.comparison_unit,
    attributes.comparison_uom,
    attributes.additional_comparison_unit,
    attributes.additional_comparison_uom,
    ARRAY_TO_STRING(restricted_pickup_types, ",",NULL) AS delivery_restrictions, 
    STRING_AGG(dc.key) AS dietary_callouts,  
  FROM `ld-ds-bi-analytics-prod.product_catalog.products`
  LEFT JOIN UNNEST(dietary_callouts) AS dc
  WHERE status = "APPROVED"
    AND liam LIKE "2%"
  GROUP BY ALL
)

SELECT * EXCEPT(article_number)
FROM rtl
JOIN pcs ON rtl.artcl_num = pcs.article_number
WHERE rtl.liam NOT IN (SELECT approved_liam FROM pcs)
ORDER BY rtl.artcl_num, total_sales_L12W DESC
