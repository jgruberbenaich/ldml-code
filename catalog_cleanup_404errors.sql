SELECT liam, brand.name_en AS brand_en, name_en, name_fr, n.en AS nav_en, n.fr AS nav_fr
FROM `ld-ds-bi-analytics-prod.product_catalog.products`
LEFT JOIN UNNEST (nav_categories) as nc
LEFT JOIN UNNEST(nc.nav_category) AS n
WHERE status = "APPROVED"
  AND liam LIKE "2%"
  AND (LOWER(name_en) LIKE "api%" 
    OR LOWER(name_fr) LIKE "api%"
    OR LOWER(n.en) LIKE "api%"
    OR LOWER(n.fr) LIKE "api%"
    OR LOWER(name_en) LIKE "cart"
    OR LOWER(name_fr) LIKE "cart"
    OR LOWER(n.en) LIKE "cart"
    OR LOWER(n.fr) LIKE "cart"
    OR LOWER(name_en) LIKE "checkout"
    OR LOWER(name_fr) LIKE "checkout"
    OR LOWER(n.en) LIKE "checkout"
    OR LOWER(n.fr) LIKE "checkout"
    OR LOWER(name_en) LIKE "account"
    OR LOWER(name_fr) LIKE "account"
    OR LOWER(n.en) LIKE "account"
    OR LOWER(n.fr) LIKE "account")