SELECT liam, article_number, ARRAY_TO_STRING(tags,",") AS pcs_tags, REGEXP_CONTAINS(IFNULL(ARRAY_TO_STRING(tags,",")," "),'prepared_in_canada') AS is_canadian
FROM `ld-ds-bi-analytics-prod.product_catalog.products`
WHERE status = "APPROVED"
  AND liam LIKE "2%"
QUALIFY COUNT(DISTINCT is_canadian) OVER(PARTITION BY article_number) > 1
