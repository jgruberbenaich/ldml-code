WITH
  prep AS (
SELECT liam,article_number, name_en, name_fr, brand.code, artcl_med_desc_en AS sap_name, UPPER(STRING_AGG(dc.key, ",")) AS callouts
FROM `ld-ds-bi-analytics-prod.product_catalog.products`
LEFT JOIN UNNEST(dietary_callouts) AS dc
JOIN `lt-dia-lake-prd-consume.product.article_curr` ON artcl_num = article_number
WHERE status = "APPROVED"
  AND liam LIKE "2%"
  AND brand.code IN ('P','PO')
GROUP BY ALL
)

SELECT *
FROM prep
WHERE ((IFNULL(callouts,'') NOT LIKE '%HORMONE%' OR IFNULL(callouts,'') NOT LIKE '%ANTIBIOTIC%' OR callouts IS NULL)
  AND (sap_name LIKE "%PC FF%" OR sap_name LIKE "%PCFF%") AND code = 'P') -- PC Free From products not tagged HORMONE_FREE or ANTIBIOTIC_FREE

  OR ((IFNULL(callouts,'') NOT LIKE '%ORGANIC%' OR callouts IS NULL)
  AND code = 'PO') -- PC Organics products not tagged ORGANIC
