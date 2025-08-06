-- Compare liams and upcs available in MARA vs MEAN vs PCS tables

WITH

pcs AS (
  SELECT article_number,
    ARRAY_AGG(liam IGNORE NULLS ORDER BY liam) AS pcs_liams,
    ARRAY_AGG(uom IGNORE NULLS ORDER BY uom) AS pcs_uoms
  FROM `ld-ds-bi-analytics-prod.product_catalog.products`
  WHERE status = "APPROVED"
    AND liam LIKE "2%"
  GROUP BY ALL
  ),

mara AS (
  SELECT LTRIM(matnr,'0') AS article, artcl_med_desc_en AS sap_name,
    MEINS AS primary_uom, 
    CONCAT(LTRIM(matnr,'0'),"_",meins) AS primary_liam,
    EAN11 AS primary_upc,
    active.article_number IS NOT NULL AS is_active
  FROM `ld-ds-bi-analytics-prod.cerebro_reporting.sap_ecc_mara`
  JOIN `lt-dia-lake-prd-consume.product.article_curr` ON LTRIM(matnr,'0') = artcl_num
  LEFT JOIN `ld-pcx-bia.Merch_PIM.PCX_ACTIVE_ARTICLE_STORES` active ON LTRIM(matnr,'0') = article_number
  WHERE LTRIM(matnr,'0') LIKE "2%"
    AND DELETED_FLAG = FALSE
  ),

mean AS (
  SELECT LTRIM(matnr,'0') AS article, 
  STRUCT ( 
    ARRAY_AGG(meinh IGNORE NULLS ORDER BY meinh) AS mean_uoms, 
    ARRAY_AGG(CONCAT(LTRIM(matnr,'0'),"_",meinh) IGNORE NULLS ORDER BY meinh) AS mean_liam,
    ARRAY_AGG(EAN11 IGNORE NULLS ORDER BY meinh) AS mean_upc,
    ARRAY_AGG(HPEAN="X" IGNORE NULLS ORDER BY meinh) AS mean_primary
    ) AS mean
  FROM `ld-ds-bi-analytics-prod.cerebro_reporting.sap_ecc_mean`
  WHERE LTRIM(matnr,'0') LIKE "2%"
    AND DELETED_FLAG = FALSE
  GROUP BY ALL
  ORDER BY article
)

SELECT * EXCEPT(article_number)
FROM mara
LEFT JOIN mean USING(article)
LEFT JOIN pcs ON mara.article = pcs.article_number
ORDER BY article