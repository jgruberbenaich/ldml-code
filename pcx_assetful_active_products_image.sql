-- Developed for Helios Data Engineering team (Colin Barber) to provide image URLs for active and approved PCX articles
WITH 

pcx_stores AS (--List of PCX enabled active stores
  SELECT DISTINCT store_number 
  FROM `ld-ds-bi-analytics-prod.bi_reporting.pcx_stores` s
  WHERE LOWER(TRIM(s.banner_name)) NOT IN ('unknown','joe fresh','tt','real canadian liquor store')
    AND CHAR_LENGTH(s.store_number) <= 4
    AND s.og_close_date > CURRENT_DATE()
    AND s.active_date <= CURRENT_DATE()
    ),

active_articles AS (--All articles that are actively assorted at the above PCX stores
  SELECT DISTINCT MATNR article_number, 
  FROM `ld-ds-bi-analytics-prod.bi_reporting.sap_active_articles`
  JOIN pcx_stores ON LTRIM(store_number,'0') = LTRIM(WERKS,'0')
  LEFT JOIN `lt-dia-lake-prd-consume.product.article_curr` ON matnr = artcl_num
  WHERE MATNR LIKE "2%"
    AND ActiveStartDate <= ActiveEndDate
  ),

pcs_products AS ( -- All article numbers in PCS with an approved liam
  SELECT article_number
  FROM `ld-ds-bi-analytics-prod.product_catalog.products`
  WHERE status = "APPROVED"
    AND liam LIKE "2%"
  ),

s3_images AS ( -- S3 image for each article - implication is that if article has any images it should have a front-EN image only.
  SELECT DISTINCT article_number, 
    url AS S3_image
  FROM `ld-ds-bi-analytics-prod.bi_reporting.pcx_product_image_avalibility`
  WHERE record_current_flag = 1 -- Use most updated record only
    AND is_image_available = TRUE -- Show URLs for articles that have images available only
  ),

pcs_images AS (
  SELECT SPLIT(liam, "_")[OFFSET(0)] AS article_number,
  COUNT(DISTINCT url) AS pcs_lang_angles
  FROM `ld-pcat-prod.cool_data_warehouse.image_angles_current`,UNNEST(image_angles) ia
  WHERE retina = TRUE
    AND breakpoint = "b1"
    AND component = "a06" -- Retina breakpoint and component should be replicated for each combination of ARTICLE-LANGUAGE-ANGLE
    AND liam LIKE "2%" -- PCX products only
    AND LOWER(angle) IN ("front","angle","side","back","top","open","closed","beauty","banner","brand") -- Accepted PCX angles only
    AND SPLIT(liam,"_")[OFFSET(0)]=SPLIT(url,"/")[OFFSET(4)] -- LIAM's article number and URL's article number must match
    AND LOWER(language) IN ('en','fr') -- Accepted languages only
  GROUP BY 1
  )

SELECT *
FROM active_articles
JOIN pcs_products USING(article_number)
LEFT JOIN s3_images USING(article_number)
LEFT JOIN pcs_images USING(article_number) -- If processing cost is too great, remove this line to save ~1TB per run.