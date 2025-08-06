WITH 
PREP_1 AS (
SELECT liam, taxonomy,nc.nav_category,
ROW_NUMBER() OVER (PARTITION BY liam) AS nav_rank
FROM `ld-ds-bi-analytics-prod.product_catalog.products`, UNNEST(nav_categories) AS nc
WHERE status = "APPROVED"
  AND liam LIKE "2%"),

PREP_2 AS (
SELECT liam,
  artcl_num,
  artcl_med_desc_en AS sap_name,
  CONCAT("L",CAST(ROW_NUMBER() OVER (PARTITION BY liam,nav_rank)-1 AS STRING)) AS level,
  mch_3_desc_en AS mch_3,
  mch_2_desc_en AS mch_2,
  mch_1_desc_en AS mch_1,
  mch_0_desc_en AS mch_0,
  mch_0_cd,
  ah_04_desc_en AS ah_4,
  ah_05_desc_en AS ah_5,
  ah_06_desc_en AS ah_6,
  ah_07_desc_en AS ah_7,
  ah_08_desc_en AS ah_8,
  ah_09_desc_en AS ah_9,
  ah_cd_max,
  ah_cd_max_val,
  taxonomy,
  en AS nav_cat,
  nav_rank,
FROM PREP_1, UNNEST(nav_category) AS nc
JOIN `lt-dia-lake-prd-consume.product.article_curr` ON SPLIT(liam,"_")[OFFSET(0)]=artcl_num)

SELECT *
FROM PREP_2
PIVOT(STRING_AGG(nav_cat) FOR level IN ("L0","L1","L2","L3","L4","L5","L6","L7","L8","L9"))
GROUP BY ALL
