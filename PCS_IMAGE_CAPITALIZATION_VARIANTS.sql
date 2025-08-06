SELECT liam, angle, breakpoint, component, language, url, UPPER(url) AS UPPERCASE -- all relevant PCS image fields
FROM `ld-pcat-prod.cool_data_warehouse.image_angles_current`
  ,UNNEST(image_angles) AS ia
  JOIN `ld-pcx-bia.Merch_PIM.PCX_ACTIVE_ARTICLE_STORES` ON SPLIT(liam,"_")[OFFSET(0)] = article_number -- limit to active PCX articles
WHERE liam LIKE "2%"
  AND retina = TRUE
  AND breakpoint = "b1"
  AND component = "a06"
QUALIFY COUNT(DISTINCT url) OVER (PARTITION BY liam) > COUNT(DISTINCT UPPER(url)) OVER (PARTITION BY liam) -- for liams where there are different capitalizations for the same URL