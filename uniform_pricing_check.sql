/*
- Tammy request on Rohit's behalf
- Items which which have a uniform price for all stores at a banner site (i.e. realcanadiansuperstore.ca, not RCSO)
- Focus on H&E, Baby, Natural Value, and Pet MCHs
- Only consider items that display a price online 
 - is approved
 - is assorted
 - has valid price and offer
 - store is from a valid PCX banner
 - account for promo pricing variations, but not MOP or PCO points
 - 1. Sale price (e.g. now $1.00 was $1.99)
 - 2. Multi-buy price (e.g. $2.00 min 2 otherwise $2.99 each)
 - 3. Limit price (e.g. $3.00 limit 10, afterwards $3.99 each)
 - 4. Regular price (e.g. $4.00)
*/

WITH

pt AS (
 SELECT DISTINCT
  liam,
  sap_name_en,
  mch_3,
  mch_2,
  mch_1,
  mch_0,
  mch_0_code,
  CASE
    WHEN mch_1 = "Toys" THEN "Toys"
    WHEN mch_1 = "Pet Food & Supplies" THEN "Pet"
    WHEN mch_2 = "Natural Foods" THEN "Natural Value"
    WHEN mch_2 = "Baby" THEN "Baby"
    WHEN mch_3 = "Home & Entertainment" THEN "H&E - excluding Toys"
    END AS product_grouping,
  CASE
   WHEN avg_weight IS NOT NULL AND selling_type <> "SOLD_BY_EACH_PRICED_BY_WEIGHT" THEN CAST(NULL AS NUMERIC)
   ELSE avg_weight
   END AS est_weight,
  L52W_pcx_sales AS L52W_og_sales,
  L52W_rtl_sales AS L52W_total_sales
 FROM `ld-pcx-bia.Merch_PIM.PCX_PRODUCT_INFORMATION_DASHBOARD`
 WHERE 1=1
  AND pcs_status = "APPROVED"
  AND active_flag = "ACTIVE"
  AND REGEXP_CONTAINS(mch_0_code,r'M07|M1002|M1025|M102113') -- MCH3 is H&E or MCH 2 is Baby or Natural Value or MCH 1 is Pet
 ),

st AS (
 SELECT DISTINCT 
  domain_name,
  LPAD(store_number,4,'0') AS store
 FROM `ld-ds-bi-analytics-prod.bi_reporting.pcx_stores` st
 WHERE 1=1
  AND IFNULL(store_banner_code,'UNKNOWN') NOT IN ('EF','JF','NN','RAPID','RCLS','TT','UNKNOWN')
  AND store_close_date > CURRENT_DATE("EST") -- Ignore stores that are permanently closed
  AND LENGTH(store_number) <= 4
  AND domain_name LIKE "%realcanadiansuperstore%"
 GROUP BY ALL
 ),

pcs AS (
 SELECT DISTINCT
  -- Show all relevant PCS offer data for products 
  domain_name,
  store,
  pt.*,
  was_price/100 AS WAS_price,
  CASE price.reason_code 
   WHEN 1 THEN "Flyer Promotions"
   WHEN 2 THEN "Long Term Promotions"
   WHEN 3 THEN "Insider Promotions"
   WHEN 4 THEN "Regular Shelf Price"
   WHEN 5 THEN "Ad Match (price matching)"
   WHEN 6 THEN "Markdowns"
   WHEN 7 THEN "Temporary Reduction OR Private Label Ad Match OR Everyday Value (MKT) OR NO FRILLS PRICE (nofrills) MAXI PRIX (Maxi)" 
   END AS reason_desc,
  price.value/100 AS price,
  CASE 
   WHEN promo.type = 1 THEN CONCAT("$",CAST(ROUND(promo.data.value/100/promo.data.quantity,2) AS STRING), " Each")
   WHEN promo.type = 2 THEN CONCAT(CAST(promo.data.quantity AS STRING), " For $", CAST(ROUND(promo.data.value/100,2) AS STRING))
   WHEN promo.type = 3 THEN CONCAT("$",CAST(ROUND(promo.data.value/100,2) AS STRING), " MIN ", CAST(promo.data.quantity AS STRING),"; otherwise $",CAST(ROUND(price.value/100,2) AS STRING), " each")
   WHEN promo.type = 4 THEN CONCAT("$",CAST(ROUND(promo.data.value/100,2) AS STRING), " LIMIT ", CAST(promo.data.quantity AS STRING),"; afterwards $",CAST(ROUND(price.value/100,2) AS STRING), " each")
   WHEN price.reason_code <> 4 AND price.value < IFNULL(was_price,0) THEN CONCAT("$", CAST(ROUND(price.value/100,2) AS STRING), " (was $", CAST(ROUND(was_price/100,2) AS STRING),")")
   WHEN price.reason_code = 4 THEN CONCAT("Regular price $",CAST(ROUND(price.value/100,2) AS STRING))
   END AS Promo_Detail,
  CAST(SPLIT(price.valid_from,"T")[SAFE_ORDINAL(1)] AS DATE) AS price_valid_from,
  CAST(SPLIT(price.valid_TO,"T")[SAFE_ORDINAL(1)] AS DATE) AS price_valid_to,
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
  JOIN pt USING(liam)
 WHERE 1=1
  AND is_assorted IS TRUE
  AND CURRENT_DATE('EST') BETWEEN DATE(ofr.valid_from) AND DATE(ofr.valid_to)
  AND CURRENT_DATE('EST') BETWEEN DATE(price.valid_from) AND DATE(price.valid_to)
  AND (promo.valid_from IS NULL
   OR (CURRENT_DATE('EST') BETWEEN DATE(promo.valid_from) AND DATE(promo.valid_to)))
  AND ofr.type = 'OG'
 QUALIFY ROW_NUMBER() OVER(PARTITION BY vendor.store_id,liam ORDER BY price_ranking DESC) = 1
 )

SELECT DISTINCT
 domain_name,
 liam,
 CONCAT(domain_name,"p/",liam) AS pdp_url,
 sap_name_en,
 mch_3,
 mch_2,
 mch_1,
 mch_0,
 mch_0_code,
 product_grouping,
 L52W_og_sales,
 L52W_total_sales,
 ROUND(SAFE_MULTIPLY(price,IFNULL(est_weight,1)),2) AS unit_price,
 IF(est_weight IS NOT NULL, price, NULL) AS kg_price,
 STRING_AGG(DISTINCT promo_detail, ",\n") AS promo_details
FROM pcs
GROUP BY ALL
QUALIFY MAX(unit_price) OVER(PARTITION BY domain_name,liam) = MIN(unit_price) OVER(PARTITION BY domain_name,liam)
ORDER BY product_grouping, liam
