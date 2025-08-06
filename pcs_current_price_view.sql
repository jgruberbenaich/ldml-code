WITH

products AS (
  SELECT DISTINCT
    liam,
    IF(selling_type = "SOLD_BY_EACH_PRICED_BY_WEIGHT",attributes.estimated_typical_weight,CAST(NULL AS NUMERIC)) AS est_weight
  FROM `ld-ds-bi-analytics-prod.product_catalog.products`
  WHERE status = "APPROVED" -- Only trust records for approved items 
  ),

st AS (
  SELECT DISTINCT 
    domain_name,
    LPAD(store_number,4,'0') AS store
  FROM `ld-ds-bi-analytics-prod.bi_reporting.pcx_stores` st
  WHERE 1=1
    AND IFNULL(store_banner_code,'UNKNOWN') NOT IN ('EF','JF','NN','RAPID','RCLS','TT','UNKNOWN')
    AND store_close_date > CURRENT_DATE("EST")  -- Ignore stores that are permanently closed
    AND LENGTH(store_number) <= 4
  GROUP BY ALL
  ),

pcs AS (
  SELECT DISTINCT
    -- Show all relevant PCS offer data for products 
    domain_name,
    store,
    liam,
    est_weight,
    was_price/100 AS WAS_price,
    CASE price.reason_code 
      WHEN 1 THEN "Flyer Promotions"
      WHEN 2 THEN "Long Term Promotions"
      WHEN 3 THEN "Insider Promotions"
      WHEN 4 THEN "Regular Shelf Price"
      WHEN 5 THEN "Ad Match (price matching)"
      WHEN 6 THEN "Markdowns"
      WHEN 7 THEN "Temporary Reduction OR Private Label Ad Match OR Everyday Value (MKT) OR NO FRILLS PRICE (nofrills) MAXI PRIX (Maxi)" 
      END AS price_detail,
    price.value/100 AS price,
    CASE 
      WHEN promo.type = 1 THEN CONCAT("$",CAST(ROUND(promo.data.value/100/promo.data.quantity,2) AS STRING), " Each") -- Discount
      WHEN promo.type = 2 THEN CONCAT(CAST(promo.data.quantity AS STRING), " For $", CAST(ROUND(promo.data.value/100,2) AS STRING))
      WHEN promo.type = 3 THEN CONCAT("$",CAST(ROUND(promo.data.value/100,2) AS STRING), " MIN ", CAST(promo.data.quantity AS STRING),"; otherwise $",CAST(ROUND(price.value/100,2) AS STRING), " each")
      WHEN promo.type = 4 THEN CONCAT("$",CAST(ROUND(promo.data.value/100,2) AS STRING), " LIMIT ", CAST(promo.data.quantity AS STRING),"; afterwards $",CAST(ROUND(price.value/100,2) AS STRING), " each")
      WHEN price.reason_code <> 4 AND price.value < IFNULL(was_price,0) THEN CONCAT("$", CAST(ROUND(price.value/100,2) AS STRING), " (was $", CAST(ROUND(was_price/100,2) AS STRING),")")
      WHEN price.reason_code <> 4 AND price.value >= IFNULL(was_price,0) THEN CONCAT("$", CAST(ROUND(price.value/100,2) AS STRING), " invalid WAS price")
      END AS promo_detail,
    CAST(SPLIT(price.valid_from,"T")[SAFE_ORDINAL(1)] AS DATE) AS price_valid_from,
    CAST(SPLIT(price.valid_to,"T")[SAFE_ORDINAL(1)] AS DATE) AS price_valid_to,
    CASE WHEN promo.reason_code > 0 THEN "Promo"
      WHEN price.reason_code = 4 THEN "Regular"
      ELSE "Special"
    END AS price_type,
    CASE WHEN promo.reason_code > 0 THEN 2
      WHEN price.reason_code = 4 THEN 0
      ELSE 1
    END AS price_ranking,
  FROM `ld-ds-bi-analytics-prod.product_catalog.offers` ofr
    LEFT JOIN UNNEST(prices) AS price
    LEFT JOIN UNNEST(promotions) AS promo
    JOIN st ON store = vendor.store_id
    JOIN products USING(liam)
  WHERE 1=1
    AND is_assorted IS TRUE
    AND CURRENT_DATE('EST') BETWEEN DATE(ofr.valid_from) AND DATE(ofr.valid_to)
    AND CURRENT_DATE('EST') BETWEEN DATE(price.valid_from) AND DATE(price.valid_to)
    AND (IFNULL(promo.type,0) > 0
      OR (CURRENT_DATE('EST') BETWEEN DATE(promo.valid_from) AND DATE(promo.valid_to)))
    AND ofr.type = 'OG'
  QUALIFY ROW_NUMBER() OVER(PARTITION BY vendor.store_id,liam ORDER BY price_ranking DESC) = 1
  )

SELECT DISTINCT
  *,
  domain_name || "p/" || liam || "?pc-express-book=" || store AS pdp_url
FROM pcs
GROUP BY ALL
ORDER BY pdp_url