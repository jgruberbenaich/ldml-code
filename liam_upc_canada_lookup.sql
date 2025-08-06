WITH 

mean AS (
SELECT 
  LTRIM(matnr,'0') AS article_number,
  meinh AS uom,
  CONCAT(LTRIM(matnr,'0'),"_",meinh) AS liam,
  ean11 AS upc,
  IFNULL(hpean,"")="X" AS is_primary_upc
FROM `ld-ds-bi-analytics-prod.cerebro_reporting.sap_ecc_mean`
WHERE DELETED_FLAG = FALSE
  AND STARTS_WITH(LTRIM(matnr,'0'),'2')
  #AND CONCAT(LTRIM(matnr,'0'),"_",meinh) IN ('20175355001_KG') -- Filter on LIAM e.g. banana
  #AND EAN11 IN ('4011') -- Filter on UPC e.g. banana
),

art AS (
  SELECT
    artcl_num AS article_number,
    artcl_med_desc_en AS sap_description,
    brnd_cd,
    mch_3_desc_en AS mch_3,
    mch_2_desc_en AS mch_2,
    mch_1_desc_en AS mch_1,
    mch_0_desc_en AS mch_0
  FROM `lt-dia-lake-prd-consume.product.article_curr`
  WHERE STARTS_WITH(artcl_num,'2')
),

pcs AS (
  SELECT 
    liam,
    REGEXP_CONTAINS(IFNULL(ARRAY_TO_STRING(tags,""),""),r'prepared_in_canada') AS is_tagged_cdn,
    name_en AS pcx_name_en
  FROM `ld-ds-bi-analytics-prod.product_catalog.products`
  WHERE status = "APPROVED"
    AND STARTS_WITH(liam,'2')
)

SELECT *
FROM mean
FULL JOIN art USING(article_number)
FULL JOIN pcs USING(liam)
WHERE liam IN ('20175355001_KG') -- Filter on LIAM e.g. banana