-- Jon Gruber-Benaich 2025-01-17

-- Purpose: 
  -- Check scheduled drug status by province

-- Steps:
  -- Run query below to check whether articles should be:
  -- forced offline (PCS status = PENDING), 
  -- banned in certain provinces, 
  -- enriched
  -- enriched and banned in certain provinces. 

-- Pull articles from SAP table ZN_ZMD_ART_PROV
-- Paste article, province, and pharm code in GSheet table `ld-pcx-bia.Merch_PIM.scheduled_drugs_sap_adhoc` at URL https://docs.google.com/spreadsheets/d/1v_YLlRwshpxLlp8PCov3fSEapr4QzQZATsqwS67M67I/edit?gid=0#gid=0

-- Consider adding in a count of the active/assorted stores in unscheduled provinces per article

WITH 
stores AS (
  SELECT province AS store_province, COUNT(DISTINCT hub_store_number) AS prov_stores
  FROM `ld-ds-bi-analytics-prod.bi_reporting.pcx_stores`
  WHERE active_date < CURRENT_DATE()
    AND store_close_date > CURRENT_DATE()
    AND og_close_date > CURRENT_DATE()
    AND TRIM(LOWER(banner_name)) NOT IN ('real canadian liquor store','tt','joe fresh')
  GROUP BY ALL
),

provinces_prep AS (
  SELECT article, 
    province, 
    CASE pharm_code
      WHEN "S2" THEN "X"
      WHEN "S3" THEN "X"
      END AS is_scheduled,
    COUNTIF(pharm_code IN ('S2','S3')) OVER(PARTITION BY article) AS scheduled_provinces, -- Count of provinces where article is scheduled
    SUM(IF(IFNULL(pharm_code,"") NOT IN ('S2','S3'),prov_stores,0)) OVER(PARTITION BY article) AS unscheduled_province_stores -- Count of stores in provinces where article is not scheduled
  FROM `ld-pcx-bia.Merch_PIM.scheduled_drugs_sap_adhoc`
    LEFT JOIN stores ON province = store_province
  WHERE province IN ('AB','BC','MB','NB','NL','NS','NT','NU','ON','PE','QC','SK','YT') -- Exclude old records like "NN"
  ),

provinces AS (
  SELECT *
  FROM provinces_prep
  PIVOT(STRING_AGG(is_scheduled) FOR province IN ('AB','BC','MB','NB','NL','NS','NT','NU','ON','PE','QC','SK','YT'))
  ),

gs1 AS (
  SELECT DISTINCT gtin_cd AS gs1_upc,
    gtin_cd IS NOT NULL AS is_gs1
  FROM `lt-dia-lake-prd-consume.product.ecommerce_content_curr`
),

mean AS (
  SELECT LTRIM(matnr,'0') AS mean_article,
    CONCAT(LTRIM(matnr,'0'),"_",meinh) AS mean_liam,
    meinh AS mean_uom,
    ean11 AS mean_UPC,
    is_gs1
  FROM `ld-ds-bi-analytics-prod.cerebro_reporting.sap_ecc_mean`
  LEFT JOIN gs1 ON LTRIM(ean11,'0') = LTRIM(gs1_upc,'0')
  WHERE DELETED_FLAG = FALSE
    AND hpean = "X" -- primary upc for liam only
    AND LTRIM(matnr,'0') LIKE "2%"
  ORDER BY mean_liam
),

sdm_pcs AS (
  SELECT liam AS sdm_liam, 
    SPLIT(liam,"_")[OFFSET(1)] AS sdm_upc
  FROM `ld-ds-bi-analytics-prod.product_catalog.products`
  WHERE status = "APPROVED"
    AND liam LIKE "SDM%"
),

pcx_pcs AS (
  SELECT article_number AS pcx_article,
    status AS pcx_status
  FROM `ld-ds-bi-analytics-prod.product_catalog.products`
  WHERE status = "APPROVED"
    AND liam LIKE "2%"
)

SELECT provinces.*,
  pcx_status,
  STRING_AGG(mean_liam,",\n") AS mean_liams,
  STRING_AGG(mean_uom,",\n") AS mean_uoms,
  STRING_AGG(mean_UPC,",\n") AS mean_upcs,
  STRING_AGG(sdm_liam,",\n") AS sdm_liams,
  MAX(is_gs1) AS is_gs1,
FROM provinces
  LEFT JOIN mean ON provinces.article = mean_article
  LEFT JOIN pcx_pcs ON provinces.article = pcx_article
  LEFT JOIN sdm_pcs ON mean_upc = sdm_upc
GROUP BY ALL
