WITH price AS 
(SELECT DISTINCT vendor.Banner AS Banner,
  vendor.store_id,
  liam,
  SAFE_DIVIDE(was_price,100) AS WAS_price,
  price.reason_code,
  price.type,
  price.value/100 AS Regular_price,
  P.data.promo_num,
  p.cond_type,
  p.data.value/100 AS promo_price,
  CASE WHEN P.type =1 THEN concat (CAST (p.data.value/100/p.data.quantity AS string), " Each")
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
WHERE
  1=1
  AND CAST(SPLIT(price.valid_from,"T")[SAFE_ORDINAL(1)] AS DATE) <= current_date ("EST")
  AND CAST(SPLIT(price.valid_TO,"T")[SAFE_ORDINAL(1)] AS DATE) >= current_date ("EST")
  AND is_assorted = TRUE
  AND vendor.pcx_enabled =TRUE)

SELECT *, Row_number()over(partition by store_id,liam order by price_ranking desc) as Ranking
FROM price
WHERE 1=1
AND liam IN ("21564314_EA") -- Change to whichever LIAMs you are looking for
AND banner IN ("maxi") -- Change to whichever banners / store_ids you are looking for
QUALIFY ranking = 1
ORDER BY store_id