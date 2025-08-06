WITH 

st AS (
  -- Relevant details for all stores
  SELECT DISTINCT
    LPAD(hub_store_number,4,'0') AS store_id,
    banner
  FROM `ld-pcx-bia.dim.stores_flip`
  WHERE open_date < CURRENT_DATE()
),

pt AS (
  -- Relevant details for all products
  SELECT liam, artcl_med_desc_en AS sap_description
  FROM `ld-ds-bi-analytics-prod.product_catalog.products`
  JOIN `lt-dia-lake-prd-consume.product.article_curr` ON article_number = artcl_num
),

o AS 
  -- PCS offer price for each active LIAM/store
(SELECT DISTINCT 
  vendor.store_id,
  liam,
  CONCAT("https://fo.pcat-prod.lblw.cloud/offers/og/store/",vendor.store_id,"/liam/",liam) AS pcs_url, -- link to PCS offers dashboard
  SAFE_DIVIDE(was_price,100) AS WAS_price,
  price.reason_code,
  CASE price.reason_code 
    WHEN 1 THEN "Flyer Promotions"
    WHEN 2 THEN "Long Term Promotions"
    WHEN 3 THEN "Insider Promotions"
    WHEN 4 THEN "Regular Shelf Price"
    WHEN 5 THEN "Ad Match (price matching)"
    WHEN 6 THEN "Markdowns"
    WHEN 7 THEN "Temporary Reduction OR Private Label Ad Match OR Everyday Value (MKT) OR NO FRILLS PRICE (nofrills) MAXI PRIX (Maxi)" 
    END AS reason_desc,
  price.type,
  price.value/100 AS Regular_price,
  P.data.promo_num,
  p.cond_type,
  p.data.value/100 AS promo_price,
  CASE WHEN P.type =1 THEN CONCAT (CAST (p.data.value/100/p.data.quantity AS string), " Each")
    WHEN P.type =2 THEN CONCAT( CAST( p.data.quantity AS string), " For ", CAST(p.data.value/100 AS string))
    WHEN P.type =3 THEN CONCAT( CAST(p.data.value/100 AS string), " Min ", CAST( p.data.quantity AS string))
    WHEN P.type =4 THEN CONCAT( CAST(p.data.value/100 AS string), " Max ", CAST( p.data.quantity AS string))
    END AS Promo_Detail,
  CAST(SPLIT(price.valid_from,"T")[SAFE_ORDINAL(1)] AS DATE) AS price_valid_from,
  CAST(SPLIT(price.valid_TO,"T")[SAFE_ORDINAL(1)] AS DATE) AS price_valid_to,
  CASE WHEN p.reason_code >0 THEN 2
    WHEN price.reason_code = 4 THEN 0
    ELSE 1
  END AS price_ranking
FROM `ld-ds-bi-analytics-prod.product_catalog.offers` a
  LEFT JOIN UNNEST(promotions) AS P
  LEFT JOIN UNNEST(prices) AS price
WHERE 1=1
  AND STARTS_WITH(liam,'2')
  AND is_assorted IS TRUE -- Exclude inactive and banned item assortments
  AND CAST(SPLIT(price.valid_from,"T")[SAFE_ORDINAL(1)] AS DATE) <= current_date ("EST")
  AND CAST(SPLIT(price.valid_TO,"T")[SAFE_ORDINAL(1)] AS DATE) >= current_date ("EST")
  AND vendor.pcx_enabled =TRUE)


-- Select all columns for items with price that is either $0.01 or $999.99
SELECT * EXCEPT(price_ranking), 
FROM o
LEFT JOIN st USING(store_id)
LEFT JOIN pt USING(liam)
WHERE 1=1
  AND (regular_price IN (0.01, 999.99) OR promo_price IN (0.01, 999.99))
QUALIFY ROW_NUMBER()OVER(PARTITION BY store_id,liam ORDER BY price_ranking DESC) = 1
ORDER BY liam,banner,store_id