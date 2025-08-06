WITH 

st AS (
  SELECT DISTINCT
    LTRIM(hub_store_number,'0') AS store_number,
      store_banner_code
  FROM `ld-ds-bi-analytics-prod.bi_reporting.pcx_stores`
),

price AS 
(SELECT DISTINCT vendor.Banner AS Banner,
  LTRIM(vendor.store_id,'0') AS store_number,
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
  CASE WHEN P.type =1 THEN concat (CAST (p.data.value/100/p.data.quantity AS string), " Each")
    WHEN P.type =2 THEN CONCAT( CAST( p.data.quantity AS string), " For ", CAST(p.data.value/100 AS string))
    WHEN P.type =3 THEN CONCAT( CAST(p.data.value/100 AS string), " Min ", CAST( p.data.quantity AS string))
    WHEN P.type =4 THEN CONCAT( CAST(p.data.value/100 AS string), " Max ", CAST( p.data.quantity AS string))
    END AS Promo_Detail,
  CAST(SPLIT(price.valid_from,"T")[SAFE_ORDINAL(1)] AS DATE) AS price_valid_from,
  CAST(SPLIT(price.valid_to,"T")[SAFE_ORDINAL(1)] AS DATE) AS price_valid_to,
  CASE WHEN p.reason_code >0 THEN 2
    WHEN price.reason_code = 4 THEN 0
    ELSE 1
  END AS price_ranking,
FROM `ld-ds-bi-analytics-prod.product_catalog.offers` a
LEFT JOIN UNNEST(promotions) AS P
LEFT JOIN UNNEST(prices) AS price
WHERE 1=1
  AND CAST(SPLIT(price.valid_from,"T")[SAFE_ORDINAL(1)] AS DATE) <= current_date ("EST")
  AND CAST(SPLIT(price.valid_TO,"T")[SAFE_ORDINAL(1)] AS DATE) >= current_date ("EST")
  AND is_assorted = TRUE
  AND vendor.pcx_enabled =TRUE)

SELECT * EXCEPT(price_ranking), 
FROM price
JOIN st USING(store_number)
WHERE 1=1
  AND liam IN ("20131344005_EA") -- Change to whichever LIAMs you are looking for
  AND store_banner_code LIKE "%RCSW%" -- Change to whichever banners / store_ids you are looking for
QUALIFY Row_number()over(partition by store_number,liam order by price_ranking desc) = 1
ORDER BY liam, store_banner_code, store_number