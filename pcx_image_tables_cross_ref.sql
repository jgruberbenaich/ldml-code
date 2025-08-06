WITH

a AS (
  SELECT artcl_num,
    artcl_med_desc_en AS sap_description,
    IFNULL(total_stores,0) AS active_stores
  FROM `lt-dia-lake-prd-consume.product.article_curr`
  LEFT JOIN `ld-pcx-bia.Merch_PIM.PCX_ACTIVE_ARTICLE_STORES` ON artcl_num = article_number
  WHERE STARTS_WITH(artcl_num,'2')
),

s3 AS (
  -- all PCX articles with S3 images
  SELECT DISTINCT article_number, url AS s3_image_url
  FROM `ld-ds-bi-analytics-prod.bi_dw.pcx_product_image_avalibility`
  WHERE 1=1
    AND record_current_flag = 1
    AND is_image_available IS TRUE
    AND STARTS_WITH(article_number, '2')
),

astfl AS (
  -- all PCX articles in the assetful table
  SELECT DISTINCT SPLIT(liam,"_")[OFFSET(0)] AS article_number,
  FROM `ld-ds-bi-analytics-prod.product_catalog.assetful_images_current`
  WHERE 1=1
    AND host_lob = 'PCX'
),

pcs AS (
  -- all PCX articles that have an approved liam in PCS
  SELECT DISTINCT article_number
  FROM `ld-ds-bi-analytics-prod.product_catalog.products`
  WHERE 1=1
    AND status = 'APPROVED'
    AND STARTS_WITH(article_number,'2')
),

fj AS (
  SELECT article_number,
    CASE WHEN pcs.article_number IS NOT NULL THEN "APPROVED IN PCS" ELSE "PENDING/NOT FOUND IN PCS" END AS pcs_status,
    CASE WHEN astfl.article_number IS NOT NULL THEN "IN ASSETFUL TABLE" ELSE "NOT FOUND" END AS assetful_status,
    CASE WHEN s3.article_number IS NOT NULL THEN "IN S3 TABLE" ELSE "NOT FOUND" END AS s3_status,
    s3_image_url
  FROM s3
  FULL JOIN astfl USING(article_number)
  FULL JOIN pcs USING(article_number)
)

SELECT *
FROM a
  LEFT JOIN fj ON artcl_num = article_number
WHERE 1=1
ORDER BY active_stores DESC
