WITH 
-- List of all dietary callouts in PCS
all_callouts AS (
  SELECT * FROM UNNEST([
    'antibiotic_free',
    'gluten_free',
    'high_fibre',
    'hormone_free',
    'lactose_free',
    'low_calories',
    'low_fat',
    'low_sodium',
    'low_sugar',
    'omega3',
    'organic',
    'peanut_free',
    'sustainable_asc',
    'sustainable_msc',
    'vegan',
    'vitamins_minerals',
    'whole_grain'
  ]) AS dc
),

-- All dietary callouts for each approved PCX liam in PCS
pcs AS (
  SELECT DISTINCT
    liam,
    STRING_AGG(dc.key) AS pcs_dc_key,
    STRING_AGG(dc.value) AS pcs_dc_value
  FROM `ld-ds-bi-analytics-prod.product_catalog.products`
    ,UNNEST(dietary_callouts) AS dc
  WHERE status = "APPROVED"
    AND STARTS_WITH(liam,'2')
  GROUP BY ALL
),

gs1_ecom_1 AS (
  SELECT DISTINCT gtin_cd AS UPC,
  -- Pull existing values for relevant fields - replace NULL values with spaces
    prod_eng_nm_desc AS productnameenglish,
    thrd_prty_logo_eng_nm AS thirdpartylogosenglish,
    tp_logo_oth_eng_txt_desc AS thirdpartylogoothertextenglish,
    onpack_prod_clm_eng_desc AS onpackproductclaimsenglish,
    allrgy_oth_txt_eng AS allergyothertextenglish,
    -- Create a mega-field out of all the fields to search for keywords.Start and end with a space. Replace all non-alphanumeric characters with a space. Replace all multiple spaces with a single space.
    REGEXP_REPLACE(REGEXP_REPLACE(LOWER(CONCAT(" ", 
      IFNULL(prod_eng_nm_desc,' ')," ",
      IFNULL(thrd_prty_logo_eng_nm,' ')," ",
      IFNULL(tp_logo_oth_eng_txt_desc,' ')," ",
      IFNULL(onpack_prod_clm_eng_desc,' ') ," ",
      IFNULL(allrgy_oth_txt_eng,' ')," ")),
      '[^a-z0-9]',' '), r'\s{2,}',' ') AS long_string
  FROM `lt-dia-lake-prd-consume.product.ecommerce_content_curr`
  ),

gs1_ecom_2 AS (
  SELECT * EXCEPT(long_string),
  -- Search mega-string for keywords and mark fields with the PCS dietary callout key if keyword appears
    SPLIT(
      RTRIM(
        CONCAT(     
          IF(REGEXP_CONTAINS(long_string," raised without antibiotics "),"antibiotic_free,",""), 
          IF(REGEXP_CONTAINS(long_string," gluten free "),"gluten_free,",""),
          IF(REGEXP_CONTAINS(long_string," high fibre "),"high_fibre,",""),
          IF(REGEXP_CONTAINS(long_string," no added hormones "),"hormone_free,",""),
          IF(REGEXP_CONTAINS(long_string," lactose free "),"lactose_free,",""),
          IF(REGEXP_CONTAINS(long_string," calorie free | low calorie | low calories | lower in calorie | no calorie | no calories ") 
            AND NOT (REGEXP_CONTAINS(long_string,"not a low calorie")),"low_calories,",""),
          IF(REGEXP_CONTAINS(long_string," low fat | less fat than "),"low_fat,",""),
          IF(REGEXP_CONTAINS(long_string," low sodium | sodium free "),"low_sodium,",""),
          IF(REGEXP_CONTAINS(long_string," no sugar | no sugars | lower in sugar | sugar free | zero sugar | 0 g sugar | 0g sugar "),"low_sugar,",""),
          IF(REGEXP_CONTAINS(long_string," source of omega 3 polyunsaturates "),"omega3,",""),
          IF(REGEXP_CONTAINS(long_string," organic "),"organic,",""),
          IF(REGEXP_CONTAINS(long_string," made in a peanut free facility | manufactured in a peanut free facility | manufactured in a nut free facility "),"peanut_free,",""),
          IF(REGEXP_CONTAINS(long_string," certified asc "),"sustainable_asc,",""), 
          IF(REGEXP_CONTAINS(long_string," certified msc "),"sustainable_msc,",""), 
          IF(REGEXP_CONTAINS(long_string," vegan "),"vegan,",""),
          IF(REGEXP_CONTAINS(long_string," source of vitamins | source of minerals | source of vitamins and minerals "),"vitamins_minerals,",""), 
          IF(REGEXP_CONTAINS(long_string," whole grain | whole grains "),"whole_grain,","")
          ),
        ","),
      ",") AS gs1_dietary_callout_array
  FROM gs1_ecom_1)

SELECT DISTINCT
  pim.liam, 
  pim.article_number, 
  gs1.* EXCEPT(gs1_dietary_callout_array),
  ARRAY_TO_STRING(gs1_dietary_callout_array,",") AS gs1_callouts,
  pcs.pcs_dc_key AS pcs_callouts,
  STRING_AGG(DISTINCT all_callouts.dc) AS combined_callouts,
FROM `ld-pcx-bia.Merch_PIM.PCX_PRODUCT_INFORMATION_DASHBOARD` AS pim
JOIN gs1_ecom_2 AS gs1 ON pim.upc = gs1.upc
LEFT JOIN pcs ON pim.liam = pcs.liam
CROSS JOIN all_callouts
LEFT JOIN UNNEST(gs1_dietary_callout_array) AS gs1_dc
WHERE 1=1
  AND pcs_status = "APPROVED"
  AND active_flag = "ACTIVE"
  AND (REGEXP_CONTAINS(pcs_dc_key,all_callouts.dc) OR REGEXP_CONTAINS(gs1_dc,all_callouts.dc))
GROUP BY ALL
HAVING LENGTH(combined_callouts) > LENGTH(IFNULL(pcs_callouts,"")) -- Only show items where the combined_callouts between GS1 and PCS is now longer than the initial PCS list
ORDER BY 1