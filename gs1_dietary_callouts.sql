WITH

dc_list AS (
  SELECT *
  FROM UNNEST(['antibiotic_free','gluten_free','high_fibre','hormone_free','lactose_free','low_calories','low_fat','low_sodium','low_sugar','omega3','organic','peanut_free','sustainable_asc','sustainable_msc','vegan','vitamins_minerals']) AS dc),

gs1_dc_1 AS (
  SELECT DISTINCT gtin_cd AS UPC,
  -- Pull existing values for relevant fields - replace NULL values with spaces
    IFNULL(prod_eng_nm_desc,' ') AS productnameenglish,
    IFNULL(thrd_prty_logo_eng_nm,' ') AS thirdpartylogosenglish,
    IFNULL(tp_logo_oth_eng_txt_desc,' ') AS thirdpartylogoothertextenglish,
    IFNULL(onpack_prod_clm_eng_desc,' ') AS onpackproductclaimsenglish,
    IFNULL(allrgy_oth_txt_eng,' ') AS allergyothertextenglish
  FROM `lt-dia-lake-prd-consume.product.ecommerce_content_curr`
  ),

gs1_dc_2 AS (
 SELECT *,
-- Create a mega-field out of all the fields to search for keywords.Start and end with a space. Replace all non-alphanumeric characters with a space. Replace all multiple spaces with a single space.
 REGEXP_REPLACE(REGEXP_REPLACE(LOWER(CONCAT(" ", productnameenglish," ",
  thirdpartylogosenglish," ",
  thirdpartylogoothertextenglish," ",
  onpackproductclaimsenglish," ",
  allergyothertextenglish," ")),'[^a-z0-9]',' '), '[ ] IS NOT NULL',' ') AS long_string 
 FROM gs1_dc_1
),

gs1_dc_3 AS (
  SELECT *,
  -- Search mega-string for keywords and mark fields as the PCS dietary callout key if keyword appears, NULL if it doesn't appear.  
      SPLIT(RTRIM(
      CASE WHEN REGEXP_CONTAINS(long_string,"calorie free|low calorie|lower in calorie| no calorie") 
        AND NOT REGEXP_CONTAINS(long_string,"not a low calorie") THEN "low_calories," ELSE "" END ||
      CASE WHEN REGEXP_CONTAINS(long_string,"gluten free") THEN "gluten_free," ELSE "" END ||
      CASE WHEN REGEXP_CONTAINS(long_string,"high fibre") THEN "high_fibre," ELSE "" END || 
      CASE WHEN REGEXP_CONTAINS(long_string,"lactose free") THEN "lactose_free," ELSE "" END ||
      CASE WHEN REGEXP_CONTAINS(long_string," low fat | less fat than ") THEN "low_fat," ELSE "" END ||
      CASE WHEN REGEXP_CONTAINS(long_string," no added hormones ") THEN "hormone_free," ELSE "" END ||
      CASE WHEN REGEXP_CONTAINS(long_string," organic ") THEN "organic," ELSE "" END ||
      CASE WHEN REGEXP_CONTAINS(long_string," made in a peanut free facility | manufactured in a peanut free facility | manufactured in a nut free facility ") THEN "peanut_free," ELSE "" END ||
      CASE WHEN REGEXP_CONTAINS(long_string," raised without antibiotics ") THEN "antibiotic_free," ELSE "" END ||
      CASE WHEN REGEXP_CONTAINS(long_string," low sodium | sodium free ") THEN "low_sodium," ELSE "" END ||
      CASE WHEN REGEXP_CONTAINS(long_string," source of omega 3 polyunsaturates ") THEN "omega3," ELSE "" END ||
      CASE WHEN REGEXP_CONTAINS(long_string," source of vitamins and minerals ") THEN "vitamins_minerals," ELSE "" END ||
      CASE WHEN REGEXP_CONTAINS(long_string," no sugar | no sugars | lower in sugar | sugar free | zero sugar | 0 g sugar | 0g sugar ") THEN "low_sugar," ELSE "" END ||    
      CASE WHEN REGEXP_CONTAINS(long_string," certified asc ") THEN "sustainable_asc," ELSE "" END ||
      CASE WHEN REGEXP_CONTAINS(long_string," certified msc ") THEN "sustainable_msc," ELSE "" END ||
      CASE WHEN REGEXP_CONTAINS(long_string," vegan ") THEN "vegan," ELSE "" END || 
      CASE WHEN REGEXP_CONTAINS(long_string," whole grain | whole grains ") THEN "whole_grain" ELSE "" END),",") as gs1_dc_array
  FROM gs1_dc_2)

SELECT gs1_dc_3.* EXCEPT(long_string, gs1_dc_array), ARRAY_AGG(dc) 
FROM gs1_dc_3
  ,UNNEST (gs1_dc_array) AS gs1_dc
JOIN dc_list ON dc = gs1_dc
GROUP BY ALL