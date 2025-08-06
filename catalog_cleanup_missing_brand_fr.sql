SELECT brand.code, brand.name_en AS brand_name_en, brand.name_fr AS brand_name_fr, COUNT(*) AS products
FROM `ld-ds-bi-analytics-prod.product_catalog.products`
WHERE brand.brand_displayable = TRUE
    AND IFNULL(brand.name_fr,"") = ""
    AND status = 'APPROVED'
    AND liam LIKE "2%"
GROUP BY ALL
ORDER BY 4 DESC