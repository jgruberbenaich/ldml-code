--MTL region query for Biweekly Enrichment Scorecard
WITH 
articles AS (
  SELECT article_number,article_desc_english AS article_description, mch_3_desc_english AS MCH_3, mch_3_code, mch_2_desc_english AS MCH_2, mch_2_code, mch_1_desc_english AS MCH_1, mch_1_code, mch_0_desc_english AS MCH_0, mch_0_code, brand_code
  FROM `ld-ds-bi-analytics-prod.bi_dw.pcx_teradata_articles`
  WHERE 1=1
    AND mch_3_code NOT IN ('M08','M13','M14','M01','M99','M06') -- REMOVES MCH3 Apparel,Floral,Garden,Goods Not For Resale - GNFR,Other/Services,Pharmacy
    AND mch_2_code NOT IN ('M0940','M0944','M0945','M1504') -- REMOVES MCH2 Eyewear,Gas Bar,Tobacco,Prestige Cosmetics
    AND mch_1_code NOT IN ('M150304','M074202','M074201','M074208','M074209','M074205','M074109','M074105','M074107','M092601') -- REMOVES MCH1 Jewellery & Fashion,Gaming,Movies,Photo Image,Portraits,Reading,Cards And Wrap,Dollar Shop,Hardware/Automotive, Spirits
    AND mch_0_code NOT IN ('M10380316','M12360103','M07420402','M07420403','M07420404','M07420405','M07420301','M07420302','M07420303','M07420305','M07420306','M07420307','M07420304','M07410415','M07411001',  'M07411007') -- REMOVES MCH0 Home Health Care,Instore Coffee Shop,Cameras,Digital Hardlines,Computers & Accessor,Printers & Supplies,Audio Accessories,Dvd/Bluray,Home Theatre,Personal Audio,Phones,Clock Radios&,Televisions&AV Acces,Ipod,Front End Bags,Calendars-Seasonal,Seasonal Other
    AND ah_5_code NOT IN ('256541') -- REMOVES INEDIBLE DECORATIONS FROM IN-STORE BAKERY
    AND NOT (mch_1_code in ('M074207') and trim(lower(article_desc_english)) LIKE '% ast')--Filter out any articles in TOYS that end in AST or ASST
    AND NOT (mch_1_code in ('M074207') and trim(lower(article_desc_english)) LIKE '% asst')
    AND NOT (mch_1_code in ('M074207') and trim(lower(article_desc_english)) LIKE '% asst %')
    AND NOT (mch_1_code in ('M074207') and trim(lower(article_desc_english)) LIKE '%mini%figure%')
    AND NOT (mch_1_code in ('M074207') and trim(lower(article_desc_english)) LIKE '%plush%')
    AND NOT (mch_1_code in ('M074207') and trim(lower(article_desc_english)) LIKE '%doll%')
    AND NOT (mch_1_code in ('M074207') and trim(lower(article_desc_english)) LIKE '%figure%')
    AND NOT (mch_1_code in ('M074207') and trim(lower(article_desc_english)) LIKE '%funko%pop%')
    AND NOT (mch_1_code in ('M074207') and trim(lower(article_desc_english)) LIKE '%fnko%pop%')
    AND NOT (mch_1_code in ('M074207') and trim(lower(article_desc_english)) LIKE '% fig %')
    AND NOT (mch_1_code in ('M074207') and trim(lower(article_desc_english)) LIKE '% 1:64 %')
    AND NOT (mch_1_code in ('M074110') and trim(lower(article_desc_english)) LIKE '% ast')
    AND NOT (mch_1_code in ('M074110') and trim(lower(article_desc_english)) LIKE '% asst')
    AND NOT (mch_1_code in ('M074110') and trim(lower(article_desc_english)) LIKE '% en %')--Filter out any articles in in Seasonal (MCH1 = M074110) that end in whole word “AST”, "ASST", "EN" 
          --Filter out any articles in HMR Ready to Eat (MCH0 = M12360101) that contains: 
    AND NOT (mch_0_code in ('M12360101') and trim(lower(article_desc_english)) LIKE '%menu%')  --the word “Menu”,
    AND NOT (mch_0_code in ('M12360101') and trim(lower(article_desc_english)) LIKE '%entree%side%') --both (“entree” and “side” in the description, eg. “Entree + 2 Sides”)
    AND NOT (mch_0_code in ('M12360101') and trim(lower(article_desc_english)) LIKE '%combo%') --the word “Combo”
    AND NOT trim(lower(article_desc_english)) LIKE '%produce reduced%' -- Filter out any articles that contains the words “produce reduce”
    AND NOT trim(lower(article_desc_english)) LIKE '%deli reduced%' -- Filter out any articles that contains the words “deli reduce”
    AND NOT trim(lower(article_desc_english)) LIKE '%open%code%' -- Filter out any articles that contains both (“open” and “code”)
    AND NOT trim(lower(article_desc_english)) LIKE '%code%open%'
    AND NOT trim(lower(article_desc_english)) LIKE '%reduction%tax%' -- Filter out any articles that contains the word “reduction”
    AND NOT trim(lower(article_desc_english)) LIKE '%reduction%pst%'
    AND NOT trim(lower(article_desc_english)) LIKE '%reduction%hst%'
    AND NOT trim(lower(article_desc_english)) LIKE '%reduction%gst%'
    AND NOT trim(lower(article_desc_english)) LIKE '%produce%reduction%'
    AND NOT trim(lower(article_desc_english)) LIKE '%random%' -- Filter out any articles that contains the word “Random”
    AND NOT trim(lower(article_desc_english)) LIKE '%en stickers%'
    AND NOT trim(lower(article_desc_english)) LIKE '%.99'
    AND NOT trim(lower(article_desc_english)) LIKE '%donation bag%'
    AND NOT trim(lower(article_desc_english)) LIKE '%veal excess%'
    AND NOT trim(lower(article_desc_english)) LIKE '%meat deal%'
    AND NOT trim(lower(article_desc_english)) LIKE '%club%deal%'
    AND NOT (mch_0_code in ('M04330104') AND trim(lower(article_desc_english)) LIKE '%cake%photo%')
    AND NOT (mch_0_code in ('M10210305') AND trim(lower(article_desc_english)) LIKE '%water%refill%')

    AND article_number NOT IN (SELECT SPLIT(trim(article_id),"_")[SAFE_OFFSET(0)] FROM `ld-pcx-bia.Merch_PIM.DNO_PRODUCT_LIST` WHERE SPLIT(trim(article_id),"_")[SAFE_OFFSET(0)] IS NOT NULL)  
    -- removes tracked articles that pc.ca team (Charlotte  O'Rourke) maintains as DNO, as these articles are maintained in Pending state regardless of enrichement status
   AND article_number NOT IN ( -- removes articles that category has indicated to be DNO, tracked and maintained by Merch Enablement
    SELECT SPLIT(trim(article_id), "_")[SAFE_OFFSET(0)] FROM `ld-pcx-bia.Merch_PIM.BACKLOG_TRACKER_CODES`)
   -- removes articles that are DNO at article
   AND article_number NOT IN (SELECT article_number FROM `ld-pcx-bia.Merch_PIM.scheduled_drugs`)),
   -- removes articles that are on the Scheduled Drugs list

sap AS (
  SELECT ean11 AS GTIN,
    LTRIM(matnr,'0') AS article_number,
    CONCAT(LTRIM(matnr,'0'),'_',CASE WHEN meins ='P01' THEN 'KG'ELSE meins END) AS liam,
    -- Convert ethnic code to ethnic department, if no department found use code
      CASE zzeth_cd WHEN "C" THEN "CARIBBEAN"
       WHEN "E" THEN "EASTERN EUROPEAN"
       WHEN "F" THEN "SOUTHEAST ASIA"
       WHEN "G" THEN "MEDITERRANEAN"
       WHEN "H" THEN "HALAL"
       WHEN "I" THEN "SOUTH EUROPEAN"
       WHEN "K" THEN "KOSHER"
       WHEN "L" THEN "LATIN AMERICAN"
       WHEN "M" THEN "MIDDLE EAST"
       WHEN "O" THEN "EAST ASIAN"
       WHEN "P" THEN "PORTUGUESE"
       WHEN "S" THEN "SOUTH ASIAN"
       WHEN "W" THEN "WESTERN EUROPEAN" ELSE zzeth_cd END as ETH_CD
  FROM `lt-dia-lake-prd-raw.product.sap_mara_curr_v`
  WHERE LTRIM(matnr,'0') LIKE "2%"
    AND meins NOT LIKE '%X%'
    AND meins NOT LIKE '%D%'
    ),

pcs AS (
  -- Pull all approved PCX articles to later exclude
  SELECT article_number
  FROM `ld-ds-bi-analytics-prod.product_catalog.products`
  WHERE status = "APPROVED"
    AND liam LIKE "2%"
  ),

brands AS (
  -- Pull unique list of brands which have at least one approved product
  SELECT DISTINCT brand.code AS brand_code, 
    brand.name_en AS brand_name,
    CASE brand.control_brand WHEN FALSE THEN "National" 
      WHEN TRUE THEN "Control" 
      END AS brand_type
  FROM `ld-ds-bi-analytics-prod.product_catalog.products`
  WHERE status = "APPROVED"
    AND liam LIKE "2%"
  ),

images AS ( 
  -- Pull url for articles which do have an imamge
    SELECT article_number, is_image_available, url 
    FROM `ld-ds-bi-analytics-prod.bi_dw.pcx_product_image_avalibility` 
    WHERE record_current_flag=1
      AND is_image_available = TRUE
      ),

responsible_prep AS (
  -- Select the division where the article is actively assorted to the most stores
  SELECT x.*, a.mch_2_desc_english AS MCH_2,
    CASE WHEN mch_2_code = 'M0926' THEN 'Liquor Team'
      WHEN GREATEST(hard_discount_stores, supermarket_stores, fortinos_stores, wholesale_stores) = hard_discount_stores THEN "Hard Discount"
      WHEN GREATEST(hard_discount_stores, supermarket_stores, fortinos_stores, wholesale_stores) = supermarket_stores THEN "Super Market"
      WHEN GREATEST(hard_discount_stores, supermarket_stores, fortinos_stores, wholesale_stores) = fortinos_stores THEN "Fortinos"
      WHEN GREATEST(hard_discount_stores, supermarket_stores, fortinos_stores, wholesale_stores) = wholesale_stores THEN "Wholesale"
      END AS division_responsible
  FROM `ld-pcx-bia.Merch_PIM.PCX_ACTIVE_ARTICLE_STORES` x
  JOIN `ld-ds-bi-analytics-prod.bi_dw.pcx_teradata_articles`  a USING(article_number)),

  vp_mch_div AS (
    -- Identify the VP responsible for that MCH2-Division combination
    SELECT article_number, responsible_prep.division_responsible, 
    CASE responsible_prep.division_responsible 
      WHEN "Fortinos" THEN "Guido" -- Guidoresponsible for all MCHs at Fortinos
      WHEN "Wholesale" THEN "Cameron" -- Cameron responsible for all MCHs at Wholesale
      ELSE vp.vp_responsible END AS vp_responsible
    FROM responsible_prep
    LEFT JOIN `ld-pcx-bia.Merch_PIM.VP_RESPONSIBLE` vp 
      ON responsible_prep.division_responsible = vp.Division_Responsible AND responsible_prep.mch_2 = vp.MCH_2 ),

  sdm AS (
    -- Identify the UPC from all the SDM liams to see if they match the UPC of any PCX product
    SELECT liam, SPLIT(liam,"_")[OFFSET(1)] AS UPC
    FROM `ld-ds-bi-analytics-prod.product_catalog.products`
    WHERE status = "APPROVED"
      AND liam LIKE "SDM_%"
  ),

  gs1 AS (
    SELECT DISTINCT gtin_cd
    FROM `lt-dia-lake-prd-consume.product.ecommerce_content_curr`),

  supplier AS (
    SELECT DISTINCT artcl_num AS article_number, STRING_AGG(DISTINCT vend_nm) AS supplier_name
    FROM `ld-ds-bi-analytics-prod.bi_dw.vendor_determination`
    WHERE vend_num <> "9999999999"
      AND vend_nm IS NOT NULL
    GROUP BY 1
  )

SELECT sap.article_number AS article,
  division_responsible,
  vp_responsible,
  superstore_stores,
  hard_discount_stores,
  core_market_stores,
  fortinos_stores,
  wholesale_stores,
  total_stores,
  activestartdate_mode,
  lcl_week_of_year_num AS activestartweek,
  lcl_year_num AS activestartyear,
  mch_3_code,
  mch_3,
  mch_2_code,
  articles.mch_2,
  mch_1_code,
  mch_1,
  mch_0_code,
  mch_0,
  brand_name,
  brand_type,
  eth_cd,
  articles.article_number,
  gtin,
  sap.liam,
  article_description,
  is_image_available,
  url,
  -- If sales/opp is Null show 0 instead, otherwise show the real sales/opp
  IFNULL(superstore_L12W,0) AS superstore_L12W,
  IFNULL(core_market_L12W,0) AS core_market_L12W,
  IFNULL(hard_discount_L12W,0) AS hard_discount_L12W,
  IFNULL(fortinos_L12W,0) AS fortinos_L12W,
  IFNULL(wholesale_L12W,0) AS wholesale_L12W,
  IFNULL(total_sales_L12W,0) AS total_sales_L12W,
  IFNULL(superstore_L52W,0) AS superstore_L52W,
  IFNULL(core_market_L52W,0) AS core_market_L52W,
  IFNULL(hard_discount_L52W,0) AS hard_discount_L52W,
  IFNULL(fortinos_L52W,0) AS fortinos_L52W,
  IFNULL(wholesale_L52W,0) AS wholesale_L52W,
  IFNULL(total_sales_L52W,0) AS total_sales_L52W,
  IFNULL(core_market_PCX_OPP_L52W,0) AS core_market_PCX_OPP_L52W,
  IFNULL(hard_discount_PCX_OPP_L52W,0) AS hard_discount_PCX_OPP_L52W,
  IFNULL(fortinos_PCX_OPP_L52W,0) AS fortinos_PCX_OPP_L52W,
  IFNULL(wholesale_PCX_OPP_L52W,0) AS wholesale_PCX_OPP_L52W,
  IFNULL(total_PCX_OPP_L52W,0) AS total_PCX_OPP_L52W,
  IF(prev.article IS NULL,0,1) AS in_scorecard,
  IF(gs1.gtin_cd IS NULL, 0,1) AS GS1,
  IF(sdm.liam IS NULL, 0,1) AS SDM,
  supplier_name
FROM articles
JOIN sap USING(article_number)
JOIN `ld-pcx-bia.Merch_PIM.PCX_ACTIVE_ARTICLE_STORES` active ON articles.article_number = active.article_number
LEFT JOIN vp_mch_div ON articles.article_number = vp_mch_div.article_number
LEFT JOIN images ON sap.article_number = images.article_number
LEFT JOIN brands ON articles.brand_code = brands.brand_code
LEFT JOIN pcs ON sap.article_number = pcs.article_number
LEFT JOIN `ld-pcx-bia.Merch_PIM.PCX_SALES_OPP_BY_DIV` t ON sap.article_number = t.article_number
LEFT JOIN sdm ON LTRIM(sap.GTIN,'0') = LTRIM(UPC,'0')
LEFT JOIN `ld-ds-bi-analytics-prod.bi_dw.dim_pcx_dates` ON DATE(activestartdate_mode) = cal_date
LEFT JOIN `ld-pcx-bia.Merch_PIM.PREVIOUS_SCORECARD_ARTICLES` prev ON sap.liam = prev.article
LEFT JOIN gs1 ON LTRIM(sap.GTIN,'0') = LTRIM(gs1.gtin_cd,'0')
LEFT JOIN supplier ON sap.article_number = supplier.article_number
WHERE pcs.article_number IS NULL -- Exclude approved PCS articles
  AND active.supply_source_inactive IS NULL -- Exclude articles which are inactive at the DC level
  AND (active.liquor_enabled = "Y" OR active.liquor_enabled IS NULL) -- Exclude liquor articles which are not assorted to any liquor-enabled stores