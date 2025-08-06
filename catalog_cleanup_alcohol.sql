WITH articles AS (
  SELECT mch_1_desc_en AS mch_1, 
    liam,  
    article_number,
    name_en,
    name_fr,
    description_en,
    description_fr,
    restricted_pickup_types,
    CASE WHEN REGEXP_CONTAINS(trim(lower(name_en)), r'id\s+required\s+at\s+pick[\s-]?up') = FALSE and REGEXP_CONTAINS(trim(lower(name_en)), r'id\s+verification\s+required\s+at\s+order\s+pick[\s-]?up') = FALSE Then 1 
      WHEN name_en is NULL Then 1  ELSE 0 END as missing_name_en, -- English title is missing "ID required at pick-up"
    CASE WHEN mch_1_desc_en = 'Spirits' THEN 0 -- Exclude RCLS liquor products
      WHEN TRIM(LOWER(name_fr)) NOT LIKE '%pièce d’identité requise au moment du ramassage%' THEN 1 
      WHEN name_fr IS NULL THEN 1 ELSE 0 END as missing_name_fr, -- French title is missing "Pièce d’identité requise au moment du ramassage" (Spirits excluded)
    CASE WHEN REGEXP_CONTAINS(trim(description_en), r'Ontario\s+only') = FALSE THEN 1 
      WHEN description_en IS NULL THEN 1 ELSE 0 END AS missing_description_en,
    CASE WHEN mch_1_desc_en = 'Spirits' THEN 0 -- Exclude RCLS liquor products
      WHEN REGEXP_CONTAINS(trim(description_fr), r'Ontario\s+seulement') = FALSE THEN 1
      WHEN description_fr is NULL THEN 1 ELSE 0 END AS missing_description_fr,
    CASE WHEN restricted_pickup_types IS NULL THEN 1 
      WHEN ARRAY_TO_STRING(restricted_pickup_types, ",") NOT LIKE "%DELIVERY%" THEN 1
      ELSE 0 END AS missing_delivery
  FROM `ld-ds-bi-analytics-prod.product_catalog.products`
    JOIN `lt-dia-lake-prd-consume.product.article_curr` ON article_number = artcl_num
  WHERE mch_2_cd = "M0926" -- Liquor products
    AND status = "APPROVED"
    AND liam LIKE "2%"
    AND REGEXP_CONTAINS(UPPER(uom),r'EA|KG|C\d')
)

SELECT articles.*,
FROM articles
WHERE missing_name_en + missing_name_fr+missing_description_en+missing_description_fr+missing_delivery > 0