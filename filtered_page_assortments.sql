-- 2025-01-20
-- Jon Gruber-Benaich
-- Provide a list of products that meet one of three conditions

  -- 1. active at nf AND pc organics brand AND under navigation 28195
  -- 2. active at nf AND pc organics brand AND under navigation code 27985 (note: articles from scenario#1 will also apply)
  -- 3. active at nf AND noname brand AND under navigation 28186


WITH

-- Identify stores which are available on nofrills.ca
nf_stores AS (
  SELECT DISTINCT LTRIM(hub_store_number,'0') AS store_number
  FROM `ld-ds-bi-analytics-prod.bi_reporting.pcx_stores`
  WHERE active_date < CURRENT_DATE("EST") -- already opened
    AND og_close_date > CURRENT_DATE("EST") -- online grocery has not been closed
    AND banner_code = "NF" -- No Frills banner
),

-- Identify active assortments (i.e. combination of store/article) for articles at nf_stores
active AS (  
  SELECT MATNR,
    COUNT(DISTINCT LTRIM(WERKS,'0')) AS nf_active_stores
  FROM `ld-ds-bi-analytics-prod.bi_reporting.sap_active_articles`
    JOIN nf_stores ON LTRIM(store_number,'0') = LTRIM(WERKS,'0')
  WHERE MATNR LIKE "2%"
    AND ActiveStartDate <= ActiveEndDate
  GROUP BY ALL
  ),

-- Identify PCS details (e.g. brand, navigation) needed to identify the relevant pages
prep AS (
SELECT liam, 
  article_number, 
  brand.name_en AS brand_name, 
  name_en AS pcx_name,
  nf_active_stores,
  STRING_AGG(nc.en,"/ ") OVER (PARTITION BY liam)  AS site_nav_en,
  CASE 
    -- Identify scenarios for relevant articles
    WHEN brand.code = "PO" AND nc.code = 28195 THEN "pcorganics_fruit&veg"
    WHEN brand.code = "PO" AND nc.code = 27985 THEN "pcorganics_food"
    WHEN brand.code = "N" AND nc.code = 28186 THEN "noname_bakingessentials"
    END AS page_filter
FROM `ld-ds-bi-analytics-prod.product_catalog.products`
  ,UNNEST(nav_categories) AS n
  ,UNNEST(n.nav_category) AS nc
JOIN active ON article_number = MATNR
WHERE status = "APPROVED"
  AND liam LIKE "2%")

-- Only show articles with one of the scenarios identified
SELECT DISTINCT *
FROM prep WHERE page_filter IS NOT NULL