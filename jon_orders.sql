WITH
user AS (
  SELECT 
  "1137131888" AS my_id,
  "2024-01-01" AS my_date
)

SELECT consumer_wallet_id, 
  trans_datetime, 
  ecom_ord_num, 
  str_site_num, 
  lcl_store_division_name, 
  lcl_store_banner_code,
  lcl_artcl_num,
  lcl_item_name,
  sales_quantity,
  sales_quantity_by_units,
  sales_amount,
  cogs
FROM `ld-ds-bi-analytics-prod.dbt_oid_transactions.mod_lcl_header`
  ,user
  ,UNNEST(lcl_item)
WHERE 1=1
  AND trans_date > DATE(my_date)
  AND consumer_wallet_id = my_id
ORDER BY trans_datetime, lcl_artcl_num