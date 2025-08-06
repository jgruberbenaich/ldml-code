SELECT *
FROM `ld-ds-bi-analytics-prod.product_catalog.assetful_images_current` , UNNEST(image_angles)
WHERE 1=2 
  OR presentation_order NOT BETWEEN 1 AND 10
  OR language NOT IN ('en','fr')
  OR host_lob NOT IN ('JF','PCX','SDM')

