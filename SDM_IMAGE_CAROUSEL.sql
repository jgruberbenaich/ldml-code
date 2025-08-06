/*
Taniya's SDM images table
SELECT LTRIM(product_code,'0') AS UPC,
  SAFE_CAST(SPLIT(url,"/")[OFFSET(6)] AS NUMERIC) AS image_num, 
  SAFE_CAST(SPLIT(url,"/")[OFFSET(8)] AS NUMERIC) AS pixels,
  url
FROM `ld-ds-bi-analytics-prod.bi_reporting.bb_product_images`
WHERE product_code LIKE  "%79400123435%"
ORDER BY pixels,image_num*/

WITH 
sdm_image_prep AS 
(SELECT liam,
  url AS image_url,
  CONCAT(IF(REGEXP_CONTAINS(UPPER(language),r"EN"),"EN",NULL),"_",gallery_index) AS image_rank
FROM `ld-pcat-prod.data_warehouse.image_angles_current`, UNNEST(image_angles) AS ia
WHERE liam LIKE "SDM_%"
  AND REGEXP_CONTAINS(UPPER(language),r"EN")
UNION ALL
SELECT liam,
  url AS image_url,
  CONCAT(IF(REGEXP_CONTAINS(UPPER(language),r"FR"),"FR",NULL),"_",gallery_index) AS image_rank
FROM `ld-pcat-prod.data_warehouse.image_angles_current`, UNNEST(image_angles) AS ia
WHERE liam LIKE "SDM_%"
  AND REGEXP_CONTAINS(UPPER(language),r"FR")
),

sdm_image_count AS (
  SELECT liam, 
    COUNTIF(image_rank LIKE "EN%") AS en_images,
    COUNTIF(image_rank LIKE "FR%") AS fr_images
  FROM sdm_image_prep
  GROUP BY 1
),

sdm_image_pivot AS ( -- Transpose list of images per language based on rank by angle
  SELECT *
  FROM sdm_image_prep
  PIVOT(STRING_AGG(image_url) FOR image_rank IN ("EN_1","EN_2","EN_3","EN_4","EN_5","EN_6","EN_7","EN_8","EN_9","EN_10","FR_1","FR_2","FR_3","FR_4","FR_5","FR_6","FR_7","FR_8","FR_9","FR_10"))
  )

SELECT *,
CASE WHEN en_images = fr_images THEN CAST(en_images AS STRING)
  WHEN en_images IS NULL AND fr_images IS NOT NULL THEN CONCAT("0 EN | ",CAST(fr_images AS STRING),"FR")
  WHEN fr_images IS NULL AND en_images IS NOT NULL THEN CONCAT(CAST(en_images AS STRING)," EN | 0 FR")
  WHEN en_images IS NOT NULL AND fr_images IS NOT NULL THEN CONCAT(CAST(en_images AS STRING)," EN| ", CAST(fr_images AS STRING), " FR")
  END AS sdm_images
FROM sdm_image_pivot
JOIN sdm_image_count USING(liam)
WHERE liam IN ("SDM_036000513554","SDM_079400123435")