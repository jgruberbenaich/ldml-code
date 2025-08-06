--MTL region query for Biweekly Enrichment Scorecard
--ARTICLE_CURR INSTEAD OF SAP_MARA & PCX_TERADATA_ARTICLES

WITH 
articles AS (
  SELECT artcl_num AS article_number,artcl_med_desc_en AS article_description, mch_3_desc_en AS MCH_3, mch_3_cd, mch_2_desc_en AS MCH_2, mch_2_cd, mch_1_desc_en AS MCH_1, mch_1_cd, mch_0_desc_en AS MCH_0, mch_0_cd, brnd_cd AS brand_code, brnd_desc_en,
  CASE brnd_ty_cd WHEN "1" THEN "CONTROL" WHEN "2" THEN "NATIONAL" END AS brnd_ty,
  bse_uom_gtin_cd AS GTIN,
  CONCAT(LTRIM(artcl_num,'0'),'_',CASE WHEN bse_uom_cd ='P01' THEN 'KG'ELSE bse_uom_cd END) AS liam,
  ethn_flg_desc_en AS ETH_CD,
  FROM `lt-dia-lake-prd-consume.product.article_curr`
  WHERE 1=1
    AND mch_3_cd NOT IN ('M08','M13','M14','M01','M99','M06') -- REMOVES MCH3 Apparel,Floral,Garden,Goods Not For Resale - GNFR,Other/Services,Pharmacy
    AND mch_2_cd NOT IN ('M0940','M0944','M0945','M1504') -- REMOVES MCH2 Eyewear,Gas Bar,Tobacco,Prestige Cosmetics
    AND mch_1_cd NOT IN ('M150304','M074202','M074201','M074208','M074209','M074205','M074109','M074105','M074107','M092601') -- REMOVES MCH1 Jewellery & Fashion,Gaming,Movies,Photo Image,Portraits,Reading,Cards And Wrap,Dollar Shop,Hardware/Automotive, Spirits
    AND mch_0_cd NOT IN ('M10380316','M12360103','M07420402','M07420403','M07420404','M07420405','M07420301','M07420302','M07420303','M07420305','M07420306','M07420307','M07420304','M07410415','M07411001',  'M07411007') -- REMOVES MCH0 Home Health Care,Instore Coffee Shop,Cameras,Digital Hardlines,Computers & Accessor,Printers & Supplies,Audio Accessories,Dvd/Bluray,Home Theatre,Personal Audio,Phones,Clock Radios&,Televisions&AV Acces,Ipod,Front End Bags,Calendars-Seasonal,Seasonal Other
    AND IFNULL(ah_05_cd,'') NOT IN ('256541') -- REMOVES INEDIBLE DECORATIONS FROM IN-STORE BAKERY
    AND NOT (mch_1_cd in ('M074207') and trim(lower(artcl_med_desc_en)) LIKE '% ast')--Filter out any articles in TOYS that end in AST or ASST
    AND NOT (mch_1_cd in ('M074207') and trim(lower(artcl_med_desc_en)) LIKE '% asst')
    AND NOT (mch_1_cd in ('M074207') and trim(lower(artcl_med_desc_en)) LIKE '% asst %')
    AND NOT (mch_1_cd in ('M074207') and trim(lower(artcl_med_desc_en)) LIKE '%mini%figure%')
    AND NOT (mch_1_cd in ('M074207') and trim(lower(artcl_med_desc_en)) LIKE '%plush%')
    AND NOT (mch_1_cd in ('M074207') and trim(lower(artcl_med_desc_en)) LIKE '%doll%')
    AND NOT (mch_1_cd in ('M074207') and trim(lower(artcl_med_desc_en)) LIKE '%figure%')
    AND NOT (mch_1_cd in ('M074207') and trim(lower(artcl_med_desc_en)) LIKE '%funko%pop%')
    AND NOT (mch_1_cd in ('M074207') and trim(lower(artcl_med_desc_en)) LIKE '%fnko%pop%')
    AND NOT (mch_1_cd in ('M074207') and trim(lower(artcl_med_desc_en)) LIKE '% fig %')
    AND NOT (mch_1_cd in ('M074207') and trim(lower(artcl_med_desc_en)) LIKE '% 1:64 %')
    AND NOT (mch_1_cd in ('M074110') and trim(lower(artcl_med_desc_en)) LIKE '% ast')
    AND NOT (mch_1_cd in ('M074110') and trim(lower(artcl_med_desc_en)) LIKE '% asst')
    AND NOT (mch_1_cd in ('M074110') and trim(lower(artcl_med_desc_en)) LIKE '% en %')--Filter out any articles in in Seasonal (MCH1 = M074110) that end in whole word “AST”, "ASST", "EN" 
          --Filter out any articles in HMR Ready to Eat (MCH0 = M12360101) that contains: 
    AND NOT (mch_0_cd in ('M12360101') and trim(lower(artcl_med_desc_en)) LIKE '%menu%')  --the word “Menu”,
    AND NOT (mch_0_cd in ('M12360101') and trim(lower(artcl_med_desc_en)) LIKE '%entree%side%') --both (“entree” and “side” in the description, eg. “Entree + 2 Sides”)
    AND NOT (mch_0_cd in ('M12360101') and trim(lower(artcl_med_desc_en)) LIKE '%combo%') --the word “Combo”
    AND NOT trim(lower(artcl_med_desc_en)) LIKE '%produce reduced%' -- Filter out any articles that contains the words “produce reduce”
    AND NOT trim(lower(artcl_med_desc_en)) LIKE '%deli reduced%' -- Filter out any articles that contains the words “deli reduce”
    AND NOT trim(lower(artcl_med_desc_en)) LIKE '%open%code%' -- Filter out any articles that contains both (“open” and “code”)
    AND NOT trim(lower(artcl_med_desc_en)) LIKE '%code%open%'
    AND NOT trim(lower(artcl_med_desc_en)) LIKE '%reduction%tax%' -- Filter out any articles that contains the word “reduction”
    AND NOT trim(lower(artcl_med_desc_en)) LIKE '%reduction%pst%'
    AND NOT trim(lower(artcl_med_desc_en)) LIKE '%reduction%hst%'
    AND NOT trim(lower(artcl_med_desc_en)) LIKE '%reduction%gst%'
    AND NOT trim(lower(artcl_med_desc_en)) LIKE '%produce%reduction%'
    AND NOT trim(lower(artcl_med_desc_en)) LIKE '%random%' -- Filter out any articles that contains the word “Random”
    AND NOT trim(lower(artcl_med_desc_en)) LIKE '%en stickers%'
    AND NOT trim(lower(artcl_med_desc_en)) LIKE '%.99'
    AND NOT trim(lower(artcl_med_desc_en)) LIKE '%donation bag%'
    AND NOT trim(lower(artcl_med_desc_en)) LIKE '%veal excess%'
    AND NOT trim(lower(artcl_med_desc_en)) LIKE '%meat deal%'
    AND NOT trim(lower(artcl_med_desc_en)) LIKE '%club%deal%'
    AND NOT (mch_0_cd in ('M04330104') AND trim(lower(artcl_med_desc_en)) LIKE '%cake%photo%')
    AND NOT (mch_0_cd in ('M10210305') AND trim(lower(artcl_med_desc_en)) LIKE '%water%refill%')

    AND artcl_num NOT IN (SELECT SPLIT(trim(liam),"_")[SAFE_OFFSET(0)] FROM `ld-pcx-bia.Merch_PIM.DNO_PC_ARTICLES` WHERE SPLIT(trim(liam),"_")[SAFE_OFFSET(0)] IS NOT NULL)  
    -- removes tracked articles that pc.ca team (Charlotte  O'Rourke) maintains as DNO, as these articles are maintained in Pending state regardless of enrichement status
   AND artcl_num NOT IN ( -- removes articles that category has indicated to be DNO, tracked and maintained by Merch Enablement
    SELECT SPLIT(trim(IFNULL(article_number,""), "_"))[SAFE_OFFSET(0)] FROM `ld-pcx-bia.Merch_PIM.CATEGORY_EXCLUSION_ARTICLES`)
   -- removes articles that are delisted PC products to prevent from appearing on pc.ca
   AND artcl_num NOT IN (SELECT article_number FROM `ld-pcx-bia.Merch_PIM.scheduled_drugs`) -- removes articles that are on the Scheduled Drugs list
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
    brand.name_en AS pcs_brand_name,
    CASE brand.control_brand WHEN FALSE THEN "NATIONAL" 
      WHEN TRUE THEN "CONTROL" 
      END AS brand_type
  FROM `ld-ds-bi-analytics-prod.product_catalog.products`
  WHERE status = "APPROVED"
    AND liam LIKE "2%"
  ),

images AS ( 
  -- Pull url for articles which do have an image
  SELECT DISTINCT article_number, 
    url,
    is_image_available
  FROM `ld-ds-bi-analytics-prod.bi_dw.pcx_product_image_avalibility`
  WHERE 1=1
    AND record_current_flag = 1
    AND is_image_available = TRUE
      ),

responsible_prep AS (
  -- Select the division where the article is actively assorted to the most stores
  SELECT x.*, MCH_2,
    CASE WHEN mch_2_cd = 'M0926' THEN 'Liquor Team'
      WHEN GREATEST(hard_discount_stores, supermarket_stores, fortinos_stores, wholesale_stores) = hard_discount_stores THEN "Hard Discount"
      WHEN GREATEST(hard_discount_stores, supermarket_stores, fortinos_stores, wholesale_stores) = supermarket_stores THEN "Super Market"
      WHEN GREATEST(hard_discount_stores, supermarket_stores, fortinos_stores, wholesale_stores) = fortinos_stores THEN "Fortinos"
      WHEN GREATEST(hard_discount_stores, supermarket_stores, fortinos_stores, wholesale_stores) = wholesale_stores THEN "Wholesale"
      END AS division_responsible
  FROM `ld-pcx-bia.Merch_PIM.PCX_ACTIVE_ARTICLE_STORES` x
  JOIN articles a USING(article_number)),

  div_vp AS (
    -- Identify the VP responsible for that MCH2-Division combination
    SELECT article_number, responsible_prep.division_responsible, 
   vp.VP_Responsible
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

  supplier_rank AS (
    SELECT vend_nm, ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT artcl_num) DESC) AS ord
      FROM `ld-ds-bi-analytics-prod.bi_dw.vendor_determination`
      WHERE artcl_num LIKE "2%" AND vend_num <> "9999999999"
      GROUP BY 1
      ORDER BY ord),

  supplier AS (
    SELECT DISTINCT artcl_num AS article_number, 
      CASE WHEN vend_num  IN (
        '0001029097', -- P&G
        '0001027911','0001028734','0001032453', -- Unilever
        '0001033136',--Mondelez
        '0001027908',--Kraft Heinz
        '0001028102','0002606406', -- General Mills
        '0001032450', -- KCC
        '0001028137', -- Cavendish
        '0001008665','0001400186','0001028081', -- PepsiCo Food
        '0001028104','0002608097' -- Danone
        ) THEN 1 ELSE 0 END AS excluded_vendor,
      STRING_AGG(vend_nm ORDER BY ord) AS supplier_name
    FROM `ld-ds-bi-analytics-prod.bi_dw.vendor_determination`
    LEFT JOIN supplier_rank USING(vend_nm)
    LEFT JOIN `ld-pcx-bia.Merch_PIM.SUPPLIER_SCORECARD_EXCLUSIONS` x ON artcl_num = x.article_number AND vend_num = x.vendor_number
    WHERE vend_num <> "9999999999"
      AND vend_nm IS NOT NULL
      AND x.article_number IS NULL
    GROUP BY 1,2
  )

SELECT articles.article_number AS article,
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
  mch_3_cd,
  mch_3,
  mch_2_cd,
  articles.mch_2,
  mch_1_cd,
  mch_1,
  mch_0_cd,
  mch_0,
  CASE WHEN pcs_brand_name IS NULL THEN brnd_desc_en ELSE pcs_brand_name END AS brand_name,
  IFNULL(brand_type, brnd_ty) AS brand_type,
  eth_cd,
  articles.article_number,
  gtin,
  articles.liam,
  article_description,
  IF(is_image_available IS NULL, FALSE, is_image_available) AS is_image_available,
  url,
  supplier_name,
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
  IFNULL(superstore_PCX_OPP_L52W,0) AS superstore_PCX_OPP_L52W,
  IFNULL(core_market_PCX_OPP_L52W,0) AS core_market_PCX_OPP_L52W,
  IFNULL(hard_discount_PCX_OPP_L52W,0) AS hard_discount_PCX_OPP_L52W,
  IFNULL(fortinos_PCX_OPP_L52W,0) AS fortinos_PCX_OPP_L52W,
  IFNULL(wholesale_PCX_OPP_L52W,0) AS wholesale_PCX_OPP_L52W,
  IFNULL(total_PCX_OPP_L52W,0) AS total_PCX_OPP_L52W,
  IF(prev.article IS NULL,0,1) AS in_scorecard,
  IF(gs1.gtin_cd IS NULL, 0,1) AS GS1,
  IF(sdm.liam IS NULL, "0",sdm.liam) AS SDM,
  CASE WHEN articles.brand_code IN ('COTT','GNIG','DPDS','HUGG','POIS','UBYK') THEN 1 ELSE excluded_vendor END AS excluded_vendor
FROM articles
JOIN `ld-pcx-bia.Merch_PIM.PCX_ACTIVE_ARTICLE_STORES` active ON articles.article_number = active.article_number
LEFT JOIN div_vp ON articles.article_number = div_vp.article_number
LEFT JOIN images ON articles.article_number = images.article_number
LEFT JOIN brands ON articles.brand_code = brands.brand_code
LEFT JOIN pcs ON articles.article_number = pcs.article_number
LEFT JOIN `ld-pcx-bia.Merch_PIM.PCX_SALES_OPP_BY_DIV` t ON articles.article_number = t.article_number
LEFT JOIN sdm ON LTRIM(articles.GTIN,'0') = LTRIM(UPC,'0')
LEFT JOIN `ld-ds-bi-analytics-prod.bi_dw.dim_pcx_dates` ON DATE(activestartdate_mode) = cal_date
LEFT JOIN `ld-pcx-bia.Merch_PIM.PREVIOUS_SCORECARD_ARTICLES` prev ON articles.article_number = prev.article
LEFT JOIN gs1 ON LTRIM(articles.GTIN,'0') = LTRIM(gs1.gtin_cd,'0')
LEFT JOIN supplier ON articles.article_number = supplier.article_number
WHERE pcs.article_number IS NULL -- Exclude approved PCS articles
  AND active.supply_source_inactive IS NULL -- Exclude articles which are inactive at the DC level
  AND (active.liquor_enabled = "Y" OR active.liquor_enabled IS NULL) -- Exclude liquor articles which are not assorted to any liquor-enabled stores