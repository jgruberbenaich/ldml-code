SELECT liam, name_en, name_fr
FROM `ld-ds-bi-analytics-prod.product_catalog.products`
WHERE status = "APPROVED"
  AND liam LIKE "2%"
  AND (REGEXP_CONTAINS(name_en,r"⅒|⅑|⅛|⅐|⅙|⅕|¼|⅓|½|⅖|⅔|⅜|⅗|¾|⅘|⅝|⅚|⅞")
    OR REGEXP_CONTAINS(name_fr,r"⅒|⅑|⅛|⅐|⅙|⅕|¼|⅓|½|⅖|⅔|⅜|⅗|¾|⅘|⅝|⅚|⅞"))