WITH
s3 AS (
  -- all PCX articles with S3 images
  SELECT DISTINCT article_number, url AS s3_image_url, artcl_med_desc_en AS sap_description
  FROM `ld-ds-bi-analytics-prod.bi_dw.pcx_product_image_avalibility`
  JOIN `lt-dia-lake-prd-consume.product.article_curr` ON article_number = artcl_num
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
)

SELECT s3.*,
  IFNULL(total_stores,0) AS active_stores,
  CASE WHEN pcs.article_number IS NOT NULL THEN "APPROVED IN PCS" ELSE "PENDING/NOT FOUND IN PCS" END AS pcs_status,
  CASE WHEN astfl.article_number IS NOT NULL THEN "IN ASSETFUL TABLE" ELSE "NOT FOUND" END AS assetful_status
FROM s3
  LEFT JOIN `ld-pcx-bia.Merch_PIM.PCX_ACTIVE_ARTICLE_STORES` ax ON s3.article_number = ax.article_number
  LEFT JOIN astfl ON s3.article_number = astfl.article_number -- filter out all articles in the assetful images table
  LEFT JOIN pcs ON s3.article_number = pcs.article_number -- filter out all approved articles in the pcs products table
WHERE 1=1
ORDER BY total_stores DESC
