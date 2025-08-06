SELECT liam, brand.code, brand.name_en AS brand_en, name_en AS pcx_name, artcl_med_desc_en AS sap_name, STRING_AGG(dc.key) AS dietary_callouts
FROM `ld-ds-bi-analytics-prod.product_catalog.products`
JOIN `lt-dia-lake-prd-consume.product.article_curr` ON artcl_num = article_number
LEFT JOIN UNNEST(dietary_callouts) AS dc
WHERE status = "APPROVED"
  AND liam LIKE "2%"
GROUP BY ALL
HAVING (code = "PO" AND LOWER(dietary_callouts) NOT LIKE "%organic%") -- PC Organic items not tagged Organic
  OR (code = "P" AND LOWER(sap_name) LIKE "%ff%" AND -- PC Free From Items
    (LOWER(dietary_callouts) NOT LIKE "%hormone%" -- not tagged Hormone Free
    OR LOWER(dietary_callouts) NOT LIKE "%antibiotic%")) -- not tagged Raised Without Antibiotics