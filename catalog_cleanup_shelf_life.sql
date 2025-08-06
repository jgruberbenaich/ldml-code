WITH s AS (
  SELECT p.liam,
    p.article_number,
    p.name_en,
    a.artcl_med_desc_en AS sap_name,
    a.mch_2_desc_en AS mch2,
    a.mch_1_desc_en AS mch1,
    a.mch_0_desc_en AS mch0,
    a.mch_0_cd AS mch,
    a.ah_04_desc_en AS ah04,
    a.ah_04_cd,
    a.ah_05_desc_en AS ah05,
    a.ah_05_cd,      
    p.attributes.shelf_life,
    CASE 
      WHEN a.mch_0_cd = 'M02270305' AND (LOWER(p.name_en) LIKE "%mini%carrot%" OR LOWER(p.name_en) LIKE "%baby%carrot%") THEN 5
      WHEN a.mch_1_cd = 'M022703' AND LOWER(p.name_en) LIKE "%snap%pea%" THEN 5 -- Refrigerated Produce (Incomplete)
      WHEN a.mch_2_cd = 'M0228' THEN 1 -- Salad Bar
      WHEN a.mch_0_cd = 'M02270303' THEN 3  -- Packaged Salads
      WHEN a.mch_2_cd = 'M1236' THEN 1 -- HMR
      WHEN a.mch_2_cd = 'M0434' THEN 4 -- Commercial Bakery
      WHEN a.mch_0_cd = "M04330102" AND ah_05_cd IN ("235418") THEN 0 -- In-Store Baguettes
      WHEN a.mch_0_cd = "M04330103" AND ah_05_cd IN ("235436","235439","235440") THEN 3 -- Savory/Buns&Rolls/Croissants In-Store Bakery
      WHEN a.mch_0_cd IN ("M04330102", "M04330103","M04330104") THEN 2 -- Bakery Breads-In-Store, Rolls-In-Store, Sweets-In-Store
      WHEN a.mch_0_cd = 'M04330101' THEN 30 --- Bakery Frozen/Seasonal-In-S 
      WHEN a.mch_0_cd = 'M03310101' THEN 5 -- Bacon
      WHEN p.liam IN ("20797680_KG","20873869_KG","20856914_KG","20863257_KG","20862936_KG","20797930_KG","20874394_KG","20874641_KG") THEN 1 -- Fortinos in-house grinds (per Eugenio Pecchia)
      WHEN (a.ah_04_cd = "258057" OR ah_05_cd IN ("258515","258599","258107","258704","258760")) AND mch_3_cd = "M03" AND liam NOT IN ("20985944_KG","21046193_KG","20985949_KG","21046194_KG","20985950_KG","20985948_KG","21368386_KG","21368418_KG","20779711_KG","21433737_KG","21433741_KG","21433743_KG","21436018_KG","21436019_KG","21433748_KG","20985951_KG","20064181_KG","20985953_KG","21404897_KG","21126398_KG","20822327_KG","20985982_KG") THEN 2 -- Fresh Ground Meats (per AH code, excludes miscategorized LIAMs)
      WHEN (LOWER(name_en) LIKE "%ground%" OR LOWER(name_en) LIKE "%grind%" OR LOWER(name_en) LIKE "%minced%") AND a.mch_3_cd = "M03" AND a.mch_1_cd NOT IN("M033101","M033102") AND a.ah_04_cd <> "233832" THEN 2 -- Fresh Ground Meats (per name, excludes frozen/processed)
      WHEN a.mch_0_cd IN ('M03310301','M03310401','M03310403','M03310701','M03310801','M03310901','M03310402') THEN 3 -- Fresh beef/exotic/lamb/pork/poultry/veal AND/OR sausage
      WHEN a.mch_1_cd = 'M113202' THEN 3 -- Fresh Seafood
      WHEN a.mch_2_cd IN ('M1022','M0535') OR a.mch_0_cd IN ('M10250110','M10250120','M02270201') THEN 5 -- Dairy, Deli, Natural Foods-Dairy, Dressing/Dips/Juices
      WHEN a.mch_0_cd IN ('M10020104','M10020106', 'M10020107') THEN 30 -- Infant Feeding, Infant Formula, Baby Natural Food
      WHEN a.mch_0_cd = 'M02270308' THEN 3 -- Value-Add Vegetables
      ELSE NULL 
    END AS updated_shelf_life,
  FROM `ld-ds-bi-analytics-prod.product_catalog.products` p
  JOIN `lt-dia-lake-prd-consume.product.article_curr` a ON p.article_number = a.artcl_num
  WHERE p.status = 'APPROVED'
      AND p.liam LIKE "2%")

SELECT s.*, COALESCE(updated_shelf_life,0)-COALESCE(shelf_life,0) AS sl_difference
FROM s
WHERE COALESCE(shelf_life,0)<>COALESCE(updated_shelf_life,0)
ORDER BY 11 DESC,9,10,4,5,6