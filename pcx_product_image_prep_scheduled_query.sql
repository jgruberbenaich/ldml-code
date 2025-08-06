WITH a AS (
  SELECT *
  FROM UNNEST(["front","angle","side","back","top","open","closed","beauty","banner","brand"]) AS angle
  WITH OFFSET AS rank)

SELECT DISTINCT liam,
  SPLIT(liam, "_")[OFFSET(0)] AS article_number,
  LOWER(url) AS image_url, 
  CONCAT(UPPER(language),"_",CAST(ROW_NUMBER() OVER (partition BY liam,language ORDER BY rank) AS STRING)) AS angle_rank,
FROM `ld-pcat-prod.cool_data_warehouse.image_angles_current`,UNNEST(image_angles) ia
  JOIN a ON LOWER(ia.angle) = LOWER(a.angle)
WHERE retina = TRUE
   AND breakpoint = "b1"
   AND component = "a06"
   AND liam LIKE "2%"
   AND SPLIT(liam,"_")[OFFSET(0)]=SPLIT(url,"/")[OFFSET(4)]
   AND UPPER(language) IN ('EN','FR')
 ORDER BY liam, angle_rank
