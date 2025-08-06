/*
Price check for upcoming flyer items as part of Flyer QA
For FP items, check the price that should appear as of the flyer break  date (i.e. Thursday of the week)
Show most relevant flyer store per banner
*/

WITH

dt AS (
/*
Date of the nearest Thursday 
e.g
  if run on Wednesday July 16 show Thursday July 17
  if run on Friday July 18 show Thursday July 24
  if run on Thursday July 31 show Thursday July 31
*/
  SELECT 
    MIN(cal_date) AS flyer_start_date
  FROM `ld-pcx-bia.dim.dates`
  WHERE 1=1
    AND cal_date >= CURRENT_DATE('EST')
    AND weekday_text_long = "Thursday"
  ),

st AS (
  -- Show all relevant store details for the list of stores getting QA'd weekly
  SELECT DISTINCT 
    LPAD(store_number,4,'0') AS store_number,
    IFNULL(store_name,nsl_store_name) AS store_name,
    CASE 
      WHEN store_banner_code = "NF" AND reporting_region = "Ontario" THEN "NFO"
      WHEN store_banner_code = "NF" AND reporting_region = "Atlantic" THEN "NFA"
      WHEN store_banner_code = "NF" AND reporting_region = "West" THEN "NFW"
      ELSE store_banner_code 
      END AS banner_code,
    province,
    domain_name
  FROM `ld-ds-bi-analytics-prod.bi_reporting.pcx_stores`
  WHERE og_close_date > CURRENT_DATE('EST')
    AND LENGTH(store_number) <= 4
    AND IFNULL(store_banner_code,'Unknown') NOT IN ('JF','NN','RCLS','Unknown') 
    AND LPAD(store_number,4,'0') IN (
      '8676', -- MAXI: 8676 (550 Rue Fleur-de-lys, Quebec)
      '7518', -- NFO GTA: 7518
      '7956', -- NFO NON GTA: 7956
      '3350', -- NFA, Mainland: 3350
      '3355', -- NFA, NFLD: 3355
      '3408', -- NFW: 3408
      '1079', -- LOB: 1079 (10 Lower Jarvis St, Toronto)
      '4033', -- YIG: 4033 (83 Underhill, Don Mills)
      '0552', -- ZEH: 0552 (323 Toronto St S, Uxbridge, ON)
      '1436', -- FORT: 1436 (700 Lawrence Ave W, North York)
      '0352', -- RASS: 0352 (650 Portland St, Halifax, Nova Scotia)
      '1077', -- RCSO: 1077 (825 Don Mills)
      '1520', -- RSCW: 1520 (3185 Grandview Hwy, Vancouver, BC)
      '7154', -- LOB 7154 Dundas & Bloor Delivery MFC
      '6885' -- RCSO 6885 Dundas & Bloor Delivery MFC
  )),

fp AS (
  -- Show all relevant details from the Weekly Force File provided by Flipp
  SELECT wff.correct_articles AS correct_liam,
    SPLIT(wff.correct_articles,"_")[SAFE_ORDINAL(1)] AS correct_article_number,
    wff.* EXCEPT(correct_articles, name),
    name AS FLIPP_NAME,
    CASE 
      WHEN Merchant ='Real Canadian Superstore' and Flyer_Run_Name = 'ONT' THEN 'RCSO'
      WHEN Merchant ='Real Canadian Superstore' and Flyer_Run_Name = 'WEST' THEN 'RCSW'
      WHEN Merchant ='Your Independent Grocer' and Flyer_Run_Name = 'ATL' THEN 'YIGA'
      WHEN Merchant ='Your Independent Grocer' and Flyer_Run_Name = 'ONT' THEN 'YIGO'
      WHEN Merchant ='Your Independent Grocer' and Flyer_Run_Name = 'WEST' THEN 'YIGW'
      WHEN Merchant ='No Frills' and Flyer_Run_Name = 'ATL' THEN 'NFA'
      WHEN Merchant ='No Frills' and Flyer_Run_Name = 'ONT' THEN 'NFO'
      WHEN Merchant ='No Frills' and Flyer_Run_Name = 'WEST' THEN 'NFW'
      WHEN Merchant ='Zehrs' THEN 'ZEHRS'
      WHEN Merchant ='Loblaws' THEN 'LOB'
      WHEN Merchant ='Provigo' THEN 'PRO'
      WHEN Merchant ='Valu-Mart' THEN 'VM'
      WHEN Merchant ='Maxi' THEN 'MAXI'
      WHEN Merchant LIKE 'Fortino%' THEN 'FORT'
      WHEN Merchant ='Atlantic Superstore' THEN 'RASS'
      WHEN Merchant ='Dominion' THEN 'DOM'
      WHEN Merchant ='Independent City Market' THEN 'VM'
      WHEN Merchant LIKE 'Wholesale Club%' THEN 'RCWC'
      END AS banner,
      CASE WHEN pcs.status = "APPROVED" THEN "APPROVED" ELSE "PENDING / NOT FOUND" END as pcs_approval_status,
      mch_3_desc_en AS mch_3,
      name_en AS PCX_NAME,
    FROM `ld-pcx-bia.Merch_Flyer.Weekly Flipp Flyer`  wff
    LEFT JOIN `lt-dia-lake-prd-consume.product.article_curr` ON SPLIT(wff.correct_articles,"_")[SAFE_ORDINAL(1)] = artcl_num
    LEFT JOIN `ld-ds-bi-analytics-prod.product_catalog.products` pcs on wff.correct_articles = pcs.liam
  ),

marc AS (
  -- Show the replenishment code i.e. DISMM for every article/store -- used to identify items that need to be forced
  SELECT 
    LTRIM(matnr,'0') AS article_number,
    LPAD(LTRIM(werks,'0'),4,'0') AS store_number,
    DISMM,
  FROM `ld-ds-bi-analytics-prod.cerebro_reporting.sap_ecc_marc`
  JOIN st ON st.store_number = LPAD(LTRIM(werks,'0'),4,'0')
  WHERE DELETED_FLAG IS FALSE
  QUALIFY ROW_NUMBER() OVER (PARTITION BY matnr, werks ORDER BY timestamp DESC) = 1
  ),

pcs AS (
  SELECT DISTINCT
    -- Show all relevant PCS offer data for products 
    vendor.store_id,
    liam,
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
      WHEN promo.type = 3 THEN CONCAT("$",CAST(ROUND(promo.data.value/100,2) AS STRING), " Min ", CAST(promo.data.quantity AS STRING))
      WHEN promo.type = 4 THEN CONCAT("$",CAST(ROUND(promo.data.value/100,2) AS STRING), " Max ", CAST(promo.data.quantity AS STRING))
      WHEN price.reason_code <> 4 AND price.value < was_price THEN CONCAT("$", CAST(ROUND(price.value/100,2) AS STRING), " (was $", CAST(ROUND(was_price/100,2) AS STRING),")")
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
    attributes.estimated_typical_weight,
  FROM `ld-ds-bi-analytics-prod.product_catalog.offers` a
    LEFT JOIN UNNEST(promotions) AS promo
    LEFT JOIN UNNEST(prices) AS price
    CROSS JOIN dt
    JOIN st ON store_number = vendor.store_id
    JOIN `ld-ds-bi-analytics-prod.product_catalog.products` USING(liam)
  WHERE 1=1
    AND flyer_start_date BETWEEN DATE(price.valid_from) AND DATE(price.valid_to)
  QUALIFY ROW_NUMBER()OVER(PARTITION BY vendor.store_id,liam ORDER BY price_ranking DESC) = 1
  )

SELECT 
  st.* EXCEPT(domain_name),
  merchant,
  flyer_run_name,
  page,
  item_id,
  position,
  correct_liam,
  flipp_name,
  pcx_name,
  pcs.* EXCEPT(store_id, liam, price_ranking),
  ROUND(estimated_typical_weight * WAS_price,2) AS est_wt_WAS_price,
  ROUND(estimated_typical_weight * price,2) AS est_wt_price,
  CONCAT("https://fo.pcat-prod.lblw.cloud/offers/og/store/",st.store_number,"/liam/",correct_liam) AS pcs_offers_url, -- link to PCS offers dashboard
  CONCAT(domain_name, "p/", correct_liam, "?pc-express-book=", st.store_number) AS pdp_url,
  mch_3,
  DISMM,
  CASE 
    WHEN mch_3 NOT IN ('Floral', 'Garden', 'Home & Entertainment')  AND DISMM in ('ND','ZA') 
      THEN "condition_1"
    -- Meat/Seafood item that's DISMM=RE and either front page or front flap
    WHEN mch_3 IN ('Meat','Seafood') AND DISMM ='RE'
      AND (page LIKE "01%" OR page LIKE "% 01 %" OR LOWER(page) LIKE "%et01%" 
        OR LOWER(page) LIKE "%flap 01%" OR LOWER(page) LIKE "%flap 02%"
        OR (LOWER(page) LIKE "%flap1%" AND LOWER(page) NOT LIKE "%online%") OR (LOWER(page) LIKE "%flap2%" AND LOWER(page) NOT LIKE "%online%")) 
      THEN 'condition_2'
  END AS force_filter,
FROM fp
  JOIN st ON fp.banner = st.banner_code
  LEFT JOIN pcs ON fp.correct_liam = pcs.liam AND st.store_number = pcs.store_id
  LEFT JOIN marc ON pcs.store_id = marc.store_number AND SPLIT(pcs.liam,"_")[SAFE_ORDINAL(1)] = marc.article_number
ORDER BY banner, st.store_number, item_id, position -- item_id and position shows the order of how items are displayed per flyer
