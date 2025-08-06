WITH 
-- Pull all PCX articles with PCS images
pcs_images AS ( 
 SELECT DISTINCT liam
 FROM `ld-pcx-bia.Merch_PIM.PCX_IMAGE_CAROUSEL`
 WHERE liam LIKE "2%"),

-- Pull relevant products (active and on PCX)
 products AS (
  SELECT liam, article_number, total_stores
  FROM `ld-ds-bi-analytics-prod.product_catalog.products`
  JOIN `ld-pcx-bia.Merch_PIM.PCX_ACTIVE_ARTICLE_STORES` USING(article_number)
  WHERE status = "APPROVED"
   AND liam LIKE "2%"
   AND REGEXP_CONTAINS(UPPER(uom),r"EA|KG|C\d")
   AND DATE(new_product_date) < CURRENT_DATE())

-- Select all active PCX articles that have S3 images but no PCS images
SELECT liam, article_number, url, total_stores
FROM `ld-ds-bi-analytics-prod.bi_dw.pcx_product_image_avalibility`
JOIN products USING(article_number) -- INNER JOIN to ensure only active articles are kept
LEFT JOIN pcs_images USING(liam)
WHERE record_current_flag = 1 -- 1 to ensure it is the most updated S3 record
 AND is_image_available = TRUE -- TRUE to ensure the article has an S3 image
 AND pcs_images.liam IS NULL -- IS NULL to ensure articles with PCS images are excluded
ORDER BY total_stores DESC