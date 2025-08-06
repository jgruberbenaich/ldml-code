WITH price AS 
(SELECT DISTINCT vendor.Banner AS Banner,
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
  END AS price_ranking,
  mch_3_desc_en AS mch_3,
  mch_2_desc_en AS mch_2,
  mch_1_desc_en AS mch_1,
  mch_0_desc_en AS mch_0,
  mch_0_cd,
  ah_04_desc_en AS ah_4,
  ah_05_desc_en AS ah_5
FROM `ld-ds-bi-analytics-prod.product_catalog.offers` a
JOIN `ld-ds-bi-analytics-prod.product_catalog.products` pcs USING(liam)
JOIN `lt-dia-lake-prd-consume.product.article_curr` ON article_number = artcl_num
LEFT JOIN UNNEST(promotions) AS P
LEFT JOIN UNNEST(prices) AS price
WHERE 1=1
  AND pcs.status = "APPROVED"
  AND liam LIKE "2%"
  AND CAST(SPLIT(price.valid_from,"T")[SAFE_ORDINAL(1)] AS DATE) <= current_date ("EST")
  AND CAST(SPLIT(price.valid_TO,"T")[SAFE_ORDINAL(1)] AS DATE) >= current_date ("EST")
  AND is_assorted = TRUE
  AND vendor.pcx_enabled =TRUE
  AND vendor.banner IS NOT NULL)

SELECT * EXCEPT(price_ranking), 
FROM price
WHERE 1=1
QUALIFY Row_number()over(partition by store_id,liam order by price_ranking desc) = 1 -- price logic for what flows to site
  AND ROW_NUMBER()OVER(PARTITION BY liam ORDER BY regular_price DESC) = 1 -- highest price only
ORDER BY regular_price DESC