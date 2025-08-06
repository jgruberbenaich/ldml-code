WITH 
PREP_1 AS (
  SELECT liam,
    description_en, 
    SPLIT(description_en,"•") AS sp
  FROM `ld-ds-bi-analytics-prod.product_catalog.products`
  JOIN `ld-pcx-bia.Merch_PIM.PCX_ACTIVE_ARTICLE_STORES` USING(article_number)
  WHERE status = "APPROVED"
    AND liam LIKE "2%"
    AND (LENGTH(description_en)>LENGTH(REPLACE(description_en,"•",""))+1 OR LENGTH(description_fr)>LENGTH(REPLACE(description_fr,"•",""))+1)
    ),

PREP_2 AS (
  SELECT liam, description_en, description_split, rnk, 
    CASE WHEN rnk = 0 THEN CONCAT("<p>",TRIM(description_split),"</p><ul>")
      WHEN rnk = ARRAY_LENGTH(sp)-1 THEN CONCAT("<li>",TRIM(description_split),"</li></ul>") 
      WHEN rnk > 0 THEN CONCAT("<li>",TRIM(description_split),"</li>") 
      END AS new_split_desc
  FROM PREP_1
  LEFT JOIN UNNEST(sp) AS description_split WITH OFFSET AS rnk
  )

SELECT liam, description_en, STRING_AGG(new_split_desc,"") AS new_desc
FROM PREP_2
GROUP BY 1,2