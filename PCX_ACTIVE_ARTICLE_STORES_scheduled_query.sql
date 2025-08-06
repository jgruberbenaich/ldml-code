WITH pcx_stores AS (--List of PCX enabled active stores
  SELECT DISTINCT store_number,banner_name,store_division,
    CASE
      WHEN REGEXP_CONTAINS(domain_name,"loblaws") THEN TRUE
      WHEN REGEXP_CONTAINS(domain_name,"maxi") THEN TRUE
      WHEN REGEXP_CONTAINS(domain_name,"newfoundlandgrocerystores") THEN TRUE
      WHEN REGEXP_CONTAINS(domain_name,"provigo") THEN TRUE
      WHEN REGEXP_CONTAINS(domain_name,"atlanticsuperstore") THEN TRUE
      WHEN REGEXP_CONTAINS(domain_name,"wholesaleclub") THEN TRUE
      WHEN REGEXP_CONTAINS(domain_name,"yourindependentgrocer") THEN TRUE
      ELSE FALSE
      END AS is_FR
  FROM `ld-ds-bi-analytics-prod.bi_reporting.pcx_stores`
  WHERE LOWER(TRIM(banner_name)) NOT IN ('unknown','joe fresh','tt')
  AND LOWER(TRIM(banner_name)) NOT IN ('real canadian liquor store') -- Remove this line if RCLS joins PCX
  AND CHAR_LENGTH(store_number) <= 4
  AND og_close_date > CURRENT_DATE()
  AND active_date <= CURRENT_DATE()),

SAP AS (--List of all active assortments (combination of store/article) for active products
  SELECT DISTINCT MATNR article_number,
    store_number,
    banner_name,
    store_division,
    is_fr,
    CASE WHEN mch_2_cd = "M0926" AND store_number IN (SELECT * FROM `ld-pcx-bia.Merch_PIM.ALCOHOL_ENABLED_STORES`) THEN 1
      WHEN mch_2_cd = "M0926" THEN 0
      ELSE NULL END AS liquor_enabled
  FROM `ld-ds-bi-analytics-prod.bi_reporting.sap_active_articles`
  JOIN pcx_stores ON LTRIM(store_number,'0') = LTRIM(WERKS,'0')
  LEFT JOIN `lt-dia-lake-prd-consume.product.article_curr` ON matnr = artcl_num
  WHERE MATNR LIKE "2%"
    AND ActiveStartDate <= ActiveEndDate
    AND MMSTA NOT IN ('P3','I3')
  ),

mode AS( -- Identify the most common ActiveStartDate for each article out of its active assortments
  SELECT MATNR AS article_number, ActiveStartDate AS activestartdate_mode
      FROM `ld-ds-bi-analytics-prod.bi_reporting.sap_active_articles`
      JOIN pcx_stores ON LTRIM(store_number,'0') = LTRIM(WERKS,'0')
      WHERE MATNR LIKE "2%"
        AND ActiveStartDate <= ActiveEndDate
        AND MMSTA NOT IN ('P3','I3')
      GROUP BY ALL
      QUALIFY ROW_NUMBER() OVER(PARTITION BY MATNR ORDER BY COUNT(*) DESC,activestartdate ASC)=1
      )

SELECT article_number,
  activestartdate_mode,
  IF(sia.article_id IS NOT NULL, "Y",NULL) AS supply_source_inactive,
  COUNTIF(store_division = "Hard Discount") AS hard_discount_stores,
  COUNTIF(store_division = "Core Market") AS core_market_stores,
  COUNTIF(store_division = "Superstore") AS superstore_stores,
  COUNTIF(store_division = "Fortinos") AS fortinos_stores,
  COUNTIF(store_division = "Wholesale") AS wholesale_stores,
  COUNTIF(store_division IN ("Core Market","Superstore")) AS supermarket_stores,
  ARRAY_AGG(DISTINCT banner_name IGNORE NULLS ORDER BY banner_name) AS active_banners,
    COUNTIF(banner_name = "Real Canadian Store Ontario") AS rcso_stores,
    COUNTIF(banner_name = "Real Canadian Store West") AS rcsw_stores,
    COUNTIF(banner_name = "Real Atlantic Superstore") AS rass_stores,
    COUNTIF(banner_name = "Dominion") AS dom_stores,
    COUNTIF(banner_name = "Loblaws") AS lob_stores,
    COUNTIF(banner_name = "Provigo") AS prov_stores,
    COUNTIF(banner_name = "Independent Grocer Atlantic") AS yiga_stores,
    COUNTIF(banner_name = "Independent Grocer Ontario") AS yigo_stores,
    COUNTIF(banner_name = "Independent Grocer West") AS yigw_stores,
    COUNTIF(banner_name = "Zehrs") AS zehr_stores,
    COUNTIF(banner_name = "Valu-Mart") AS vm_stores,
    COUNTIF(banner_name = "Extra Foods") AS ef_stores,
    COUNTIF(banner_name = "Maxi") AS maxi_stores,
    COUNTIF(banner_name = "No Frills") AS nf_stores,
  COUNTIF(is_FR = TRUE) AS fr_stores,
  COUNT(*) AS total_stores,
  CASE WHEN SUM(liquor_enabled) IS NULL THEN NULL
    WHEN SUM(liquor_enabled) > 0 THEN "Y"
    WHEN SUM(liquor_enabled) = 0 THEN "N"
    END AS liquor_enabled
FROM SAP
LEFT JOIN mode USING(article_number)
LEFT JOIN `ld-pcx-bia.Merch_PIM.supply_source_inactive_articles` sia ON sap.article_number = article_id
GROUP BY ALL
ORDER BY 1