WITH 

mean AS (
  SELECT DISTINCT 
    CONCAT(LTRIM(matnr,'0'),"_",meinh) AS mean_liam,
    LTRIM(matnr,'0') AS mean_article,
    meinh AS mean_uom,
    STRING_AGG(DISTINCT CASE WHEN hpean = "X" THEN ean11 END, " | ") AS mean_primary_upc,
    STRING_AGG(DISTINCT CASE WHEN hpean <> "X" OR hpean IS NULL THEN ean11 END, " | ") AS mean_alternate_upcs,
    ARRAY_AGG(DISTINCT CASE WHEN hpean <> "X" OR hpean IS NULL THEN ean11 END IGNORE NULLS) AS alternate_UPC
  FROM `ld-ds-bi-analytics-prod.cerebro_reporting.sap_ecc_mean`
  WHERE LTRIM(matnr,'0') LIKE "2%"
    AND deleted_flag = FALSE
  GROUP BY ALL
),  

sap AS (
  -- Find relevant SAP info for all PCX articles, including those outside of our scope
  SELECT DISTINCT bse_uom_gtin_cd AS mara_UPC,
    artcl_num AS article_number,
    CONCAT(artcl_num,"_", CASE bse_uom_cd  WHEN "P01" THEN "KG" ELSE bse_uom_cd END) AS mara_liam,
    bse_uom_cd AS mara_uom,
    cs_pk_qty AS sap_packsize,
    SAFE_CAST(bse_ut_sz_qty AS NUMERIC) AS sap_itemsize,
    bse_ut_sz_uom_cd AS sap_itemuom,
    DATE(artcl_cre_dt) AS sap_creationdate,
    ethn_flg_desc_en as ETH_CD,
    brnd_cd AS sap_brand,
    brnd_desc_en AS sap_brand_en,
    brnd_desc_fr AS sap_brand_fr,
    CASE brnd_ty_cd WHEN "1" THEN TRUE WHEN "2" THEN FALSE END AS sap_control_brand,
    artcl_med_desc_en AS sap_name_en, 
    artcl_med_desc_fr AS sap_name_fr,
  mch_3_desc_en AS mch_3, mch_2_desc_en AS mch_2, mch_1_desc_en AS mch_1, mch_0_desc_en AS mch_0, mch_0_cd AS mch_0_code, ah_04_desc_en AS ah_4, ah_05_desc_en AS ah_5,
  CASE WHEN mch_3_cd IN ('M02','M03','M04','M05','M11','M12') -- Produce, Meat, Bakery, Deli, Seafood, HMR
        OR mch_2_cd IN ('M1022','M1023','M1024') -- COS>Dairy> Frozen, Bulk
        OR mch_1_cd IN ('M102101','M102102','M102103','M102104','M102105','M102106','M102107','M102108','M102109','M102110','M102116') -- COS>GROCERY> Breakfast, Hot Beverages & Accessories, Cold Beverages, Confectionary, Snacks, Baking, Canned, Meal Makers, Condiments, Salad Fixings, Confectionary - Seasonal
        OR mch_0_cd IN ('M10020104',"M10250101","M10250103","M10250104","M10250105","M10250106","M10250107","M10250108","M10250109","M10250110","M10250111","M10250114","M10250115","M10250116","M10250118","M10250119","M10250120") THEN "FOOD" ELSE "NON-FOOD" END AS food_flag, -- COS>Baby> Infant Feeding, COS>Natural Foods>Natural Foods> Active Lifestyle-Nat,Bakery-Natural Foods,Baking / Bulk-Natura,Beverages-Natural Fo,Breakfast-Natural Fo,Canned-Natural Foods,Condiments / Salad F,Confectionary / Bars,Dairy-Natural Foods,Frozen-Natural Foods,Hot Beverages-Natura,Household Needs-Natu,Meal Makers-Natural,Snacks-Natural Foods,Vitamin/Mineral/Supp,Milk - Natural Foods
    CASE WHEN mch_3_cd IN ('M01','M06','M08','M13','M14','M99') -- REMOVES mch3 Apparel,Floral,Garden,Goods Not For Resale - GNFR,Other/Services,Pharmacy
      OR mch_2_cd IN ('M0940','M0944','M0945','M1504') -- REMOVES mch2 Eyewear,Gas Bar,Tobacco,Prestige Cosmetics
      OR mch_1_cd IN ('M150304','M074202','M074201','M074208','M074209','M074205','M074109','M074105','M074107','M092601') -- REMOVES mch1 Jewellery & Fashion,Gaming,Movies,Photo Image,Portraits,Reading,Cards And Wrap,Dollar Shop,Hardware/Automotive, Spirits
      OR mch_0_cd IN ('M10380316','M12360103','M07420402','M07420403','M07420404','M07420405','M07420301','M07420302','M07420303','M07420305','M07420306','M07420307','M07420304','M07410415','M07411001',  'M07411007') -- REMOVES mch0 Home Health Care,Instore Coffee Shop,Cameras,Digital Hardlines,Computers & Accessor,Printers & Supplies,Audio Accessories,Dvd/Bluray,Home Theatre,Personal Audio,Phones,Clock Radios&,Televisions&AV Acces,Ipod,Front End Bags,Calendars-Seasonal,Seasonal Other
      OR ah_05_cd IN ('256541') -- REMOVES INEDIBLE DECORATIONS FROM IN-STORE BAKERY
    THEN "INACTIVE MCH" ELSE "ACTIVE MCH" END AS mch_flag,
  FROM `lt-dia-lake-prd-consume.product.article_curr`
  WHERE artcl_num LIKE "2%"
  ),

brands AS (
  SELECT DISTINCT
    brand.code AS pcs_brand,
    brand.name_en AS pcs_brand_en,
    brand.name_fr AS pcs_brand_fr,
    brand.control_brand AS pcs_control_brand,
    brand.brand_displayable
  FROM `ld-ds-bi-analytics-prod.product_catalog.products`
  WHERE status = "APPROVED"
    AND liam LIKE "2%"
    ),

pcs AS (
  -- Select all the relevant PCS info for APPROVED products with a relevant UOM (PENDING articles will not appear in the table)
  SELECT liam AS pcs_liam,
    article_number,
    brand.sub_brand.name_en AS subbrand_en,
    brand.sub_brand.name_fr AS subbrand_fr,
    name_en AS pcx_name_en,
    name_fr AS pcx_name_fr,
    description_en AS pcx_desc_en,
    description_fr AS pcx_desc_fr,
    CONCAT(IF(attributes.items_per_package>1,CONCAT(CAST(attributes.items_per_package AS STRING),"x"),""),CAST(attributes.item_size AS STRING), attributes.item_size_uom) AS product_size,
    uom AS pcs_uom,
    CAST(attributes.items_per_package AS STRING) AS pcs_items_per_package,
    attributes.item_size AS pcs_item_size,
    attributes.item_size_uom AS pcs_item_size_uom,
    attributes.sold_by_incr,
    attributes.sold_by_unit,
    attributes.sold_by_uom,
    attributes.estimated_typical_weight AS avg_weight,
    DATE(new_product_date) AS pcs_approval_date,
    attributes.relative_delivery_quantity,
    attributes.shelf_life,
    attributes.min_order_quantity,
    attributes.max_order_quantity,
    attributes.comparison_unit,
    attributes.comparison_uom,
    attributes.additional_comparison_unit,
    attributes.additional_comparison_uom,
    selling_type,
    IF(EXTRACT(YEAR FROM DATE(new_product_date)) = EXTRACT(YEAR FROM CURRENT_DATE("EST")), "CY","BEFORE CY") AS CY_flag,
    tags AS pcs_tags,
    restricted_pickup_types,
    ARRAY_TO_STRING(restricted_pickup_types, ", ") AS pickup_restrictions,
    keywords_en AS pcs_keywords_en_filter

  FROM `ld-ds-bi-analytics-prod.product_catalog.products`
  WHERE status = "APPROVED"
    AND liam LIKE "2%"
    ),

nutr AS (
    -- Find nutrients for each liam in the products table
  SELECT liam,
    STRING_AGG(CONCAT(n.key,":",n.value)) AS nutrients,
  FROM `ld-ds-bi-analytics-prod.product_catalog.products`
    ,UNNEST(nutrition.recipes) as nr    
    ,UNNEST(nr.nutrients) n
  WHERE status = "APPROVED"
    AND liam LIKE "2%"
    
  GROUP BY 1
  ),

ingr AS (
  -- Find ingredients (en/fr) for each article in the products table
  SELECT liam,
    STRING_AGG(nr.ingredients.en) AS ingredients_en,
    STRING_AGG(nr.ingredients.fr) AS ingredients_fr,
  FROM `ld-ds-bi-analytics-prod.product_catalog.products`
    ,UNNEST(nutrition.recipes) as nr
  WHERE status = "APPROVED"
    AND liam LIKE "2%"
  GROUP BY 1
  ),

navigation AS (
  -- Find navigation categories (site navigation breadcrumbs) for each article in products view
  SELECT liam, 
    STRING_AGG(nc.en, ", ") AS site_nav_en,
    STRING_AGG(nc.fr, ", ") AS site_nav_fr
  FROM `ld-ds-bi-analytics-prod.product_catalog.products`, UNNEST (nav_categories) as n, UNNEST(n.nav_category) AS nc
  WHERE status = "APPROVED"
    AND liam LIKE "2%"
  GROUP BY 1
  ),

dietarycallouts AS (
  -- Concatenate all dietary callouts for the article
  SELECT liam,
    ARRAY_AGG(JSON_VALUE(dc.value,'$.en') ORDER BY (JSON_VALUE(dc.value,'$.en'))) AS dietary_filter,
    STRING_AGG(JSON_VALUE(dc.value,'$.en') ORDER BY JSON_VALUE(dc.value,'$.en')) AS dietary_callouts
  FROM `ld-ds-bi-analytics-prod.product_catalog.products`, UNNEST (dietary_callouts) as dc
  WHERE status = "APPROVED"
    AND liam LIKE "2%"
  GROUP BY 1
  ),

s3 AS (
  -- S3/Elzar image for each article
  SELECT DISTINCT article_number, 
    url AS S3_image
  FROM `ld-ds-bi-analytics-prod.bi_reporting.pcx_product_image_avalibility`
  WHERE record_current_flag = 1
    AND is_image_available = TRUE
),

assetful AS (
  SELECT liam,
  MAX_BY(assetful_url,is_primary) AS primary_assetful_img,
  CASE 
    WHEN COUNTIF(language='en') =COUNTIF(language='fr') THEN CAST(COUNTIF(language='en') AS STRING)
    ELSE CONCAT(
      CAST(COUNTIF(language='en') AS STRING),"EN",
      " | ",
      CAST(COUNTIF(language='fr') AS STRING),"FR")
    END AS assetful_images
  FROM `ld-pcx-bia.Merch_PIM.assetful_images_current_url`
  GROUP BY ALL
  ),

gs1 AS (
  SELECT DISTINCT
    LTRIM(gtin_cd,'0') AS UPC,
    TRIM(INITCAP(CONCAT(IFNULL(fnc_eng_nm,"")," ",IFNULL(var_eng_desc,"")))) AS GS1_name_en,
    TRIM(CONCAT(IFNULL(fnc_fr_nm,"")," ",IFNULL(var_fr_desc,""))) AS GS1_name_fr,
    CASE 
  WHEN addedfeat_and_bnft_eng_desc = brnd_own_prod_mkt_eng_msg 
    THEN `ld-pcx-bia.Merch_PIM`.CONVERT_TO_HTML(addedfeat_and_bnft_eng_desc) 
  ELSE CONCAT(IFNULL(CONCAT("<p>",REPLACE(REGEXP_REPLACE(brnd_own_prod_mkt_eng_msg,"\n","</p><p>"),"</p><p></p>","</p>"),"</p>"),""), `ld-pcx-bia.Merch_PIM`.CONVERT_TO_HTML(addedfeat_and_bnft_eng_desc) ) 
  END AS gs1_desc_en,
CASE 
  WHEN addedfeat_and_bnft_fr_desc = brnd_own_prod_mkt_fr_msg 
    THEN `ld-pcx-bia.Merch_PIM`.CONVERT_TO_HTML(addedfeat_and_bnft_fr_desc)
  ELSE CONCAT(IFNULL(CONCAT("<p>",REPLACE(REGEXP_REPLACE(brnd_own_prod_mkt_fr_msg,"\n","</p><p>"),"</p><p></p>","</p>"),"</p>"),""), `ld-pcx-bia.Merch_PIM`.CONVERT_TO_HTML(addedfeat_and_bnft_fr_desc)) END AS gs1_desc_fr
  FROM `lt-dia-lake-prd-consume.product.ecommerce_content_curr`
),

sdm AS (
  SELECT liam AS sdm_liam,
    LTRIM(SPLIT(liam,"SDM_")[OFFSET(1)],'0') AS upc
  FROM `ld-ds-bi-analytics-prod.product_catalog.products`
  WHERE status = "APPROVED"
    AND liam LIKE "SDM_%"
),

supplier AS (
  SELECT artcl_num AS article_number,
    ARRAY_AGG(DISTINCT IFNULL(rolodex_name,vend_nm) IGNORE NULLS) AS supplier_filter,
    STRING_AGG(DISTINCT IFNULL(rolodex_name,vend_nm)) AS supplier_name -- Use rolodex name if known, otherwise use vendor name
  FROM `ld-ds-bi-analytics-prod.bi_dw.vendor_determination` vd
  LEFT JOIN `ld-pcx-bia.Merch_PIM.SUPPLIER_ROLODEX` sr ON LTRIM(VENDOR_NUMBER,'0') = LTRIM(vend_num,'0')
  LEFT JOIN `ld-pcx-bia.Merch_PIM.SUPPLIER_SCORECARD_EXCLUSIONS` x ON LTRIM(x.vendor_number,'0') = LTRIM(vd.vend_num,'0') AND x.article_number = vd.artcl_num -- Exclude known mistakes from vendor table
  WHERE x.article_number IS NULL
    AND vend_num <> "9999999999" -- Ignore the Multi-Vend entries
  GROUP BY 1
  ),

pcx_sales AS (
  SELECT CONCAT(article_id, "_", sales_uom_cd) AS liam,
    SUM(IF(transaction_dt > CURRENT_DATE()-84,sales_amt,0)) AS L12W_pcx_sales,
    SUM(sales_amt) AS L52W_pcx_sales,
    SUM(IF(EXTRACT(YEAR FROM transaction_dt) = EXTRACT(YEAR FROM CURRENT_DATE()),sales_amt,0)) AS CY_pcx_sales
  FROM `ld-ds-bi-analytics-prod.bi_reporting.sl_trans_qlfy_ecom_dly`
  WHERE transaction_dt > CURRENT_DATE()-365 -- REQUIRED to put a transaction_dt filter on
    AND article_acct_assn_grp_cd IN ('01','21') -- ALWAYS use this filter on this table
    AND ecom_ind IN ('1','4','5','6','7') -- ALWAYS exclude JoeFresh/ShipFromStore channels, include ICD, PCXP, PCXD, DD, P&D
    AND article_id LIKE "2%"
  GROUP BY ALL
),

stores AS (
  -- list of stores where 
  SELECT DISTINCT hub_store_number AS store_number
  FROM `ld-ds-bi-analytics-prod.bi_reporting.pcx_stores`
  WHERE LOWER(TRIM(banner_name)) NOT IN ('unknown','joe fresh','tt','real canadian liquor store') --  Exclude TT, Unknown, JF
    AND CHAR_LENGTH(store_number) <= 4
    AND og_close_date > CURRENT_DATE()
    AND active_date <= CURRENT_DATE()
  ),

rtl_sales AS (
  SELECT CONCAT(artcl_num, "_",sl_uom_cd) AS liam,
    SUM(IF(trans_dt > CURRENT_DATE()-84,prrtd_pstd_sl_amt,0)) AS L12W_rtl_sales,
    SUM(prrtd_pstd_sl_amt) AS L52W_rtl_sales,
    SUM(IF(EXTRACT(YEAR FROM trans_dt) = EXTRACT(YEAR FROM CURRENT_DATE()),prrtd_pstd_sl_amt,0)) AS CY_rtl_sales
  FROM `lt-dia-lake-prd-consume.financial_reporting.sales_lcl_store_article_dly`
    JOIN stores ON LTRIM(store_number,'0') = LTRIM(site_num,'0') -- Only count sales at stores which are PCX enabled
  WHERE trans_dt > CURRENT_DATE()-365 -- REQUIRED TO put a trans_dt filter
    AND artcl_acct_assn_grp_cd IN ('01','21') -- ALWAYS use this filter on this table
    AND artcl_num LIKE "2%"
  GROUP BY ALL
  ),

master_liam AS (
  SELECT liam,
    CASE WHEN mara_uom = "P01" THEN mean_primary_upc
      WHEN mara_liam = pcs_liam OR pcs_liam IS NULL THEN mara_upc
      WHEN mean_primary_upc IS NOT NULL THEN mean_primary_upc
      WHEN mean_primary_upc IS NULL THEN mean_alternate_upcs END AS UPC,
    IFNULL(pcs_brand,sap_brand) AS brand_code,
    IFNULL(pcs_control_brand,sap_control_brand) AS control_brand,
    IFNULL(pcs_brand_en,sap_brand_en) AS brand_en,
    IFNULL(pcs_brand_fr,sap_brand_fr) AS brand_fr,
    sap.*,
    pcs.* EXCEPT(article_number),
    brands.*,
    mean.*
  FROM `ld-pcx-bia.Merch_PIM.master_liam` l
  JOIN sap ON l.article = sap.article_number
  LEFT JOIN pcs ON l.liam = pcs_liam
  LEFT JOIN brands ON sap_brand = pcs_brand
  LEFT JOIN mean ON l.liam = mean_liam
)

SELECT DISTINCT master_liam.* EXCEPT(sap_brand),
  CASE WHEN brand_displayable = FALSE AND food_flag = "FOOD" THEN "WHITE LABEL" 
    WHEN control_brand = TRUE THEN "CONTROL"
    WHEN control_brand = FALSE THEN "NATIONAL"
    END AS brand_type,
  CASE WHEN SPLIT(master_liam.liam,"_")[OFFSET(1)] IS NOT NULL AND mara_uom IS NOT NULL AND SPLIT(master_liam.liam,"_")[OFFSET(1)]=mara_uom THEN "PRIMARY UOM"
    WHEN SPLIT(master_liam.liam,"_")[OFFSET(1)] IS NOT NULL AND mara_uom IS NOT NULL AND SPLIT(master_liam.liam,"_")[OFFSET(1)]<>mara_uom THEN "SECONDARY UOM" END AS uom_type,
  CASE WHEN DATE(pcs_approval_date) > CURRENT_DATE("EST")-90 THEN "NEW"
    WHEN DATE(pcs_approval_date) <= CURRENT_DATE("EST")-90 THEN "NOT NEW"
    ELSE "PENDING/NOT FOUND" END AS new_flag,

  navigation.* EXCEPT(liam),

  s3.* EXCEPT(article_number),
  
  assetful.* EXCEPT(liam),

  i.* EXCEPT(liam,article_number),

  d.* EXCEPT(liam),

  nutr.* EXCEPT(liam),
    CASE WHEN food_flag="NON-FOOD" THEN "NON-FOOD" 
      WHEN nutrients IS NULL OR LENGTH(nutrients) <2 THEN "MISSING"
      WHEN LENGTH(nutrients) >=2 THEN "SHOWING" END AS nutr_flag,
  ingr.* EXCEPT(liam),
    CASE WHEN food_flag="NON-FOOD" THEN "NON-FOOD" 
      WHEN ingredients_en IS NULL OR LENGTH(ingredients_en) <2 THEN "MISSING"
      WHEN LENGTH(ingredients_en) >=2 THEN "SHOWING" END AS ingr_en_flag,
    CASE WHEN food_flag="NON-FOOD" THEN "NON-FOOD" 
      WHEN ingredients_fr IS NULL OR LENGTH(ingredients_fr) <2 THEN "MISSING"
      WHEN LENGTH(ingredients_fr) >=2 THEN "SHOWING" END AS ingr_fr_flag,

  active.* EXCEPT(article_number),
  IF(active.article_number IS NOT NULL, "ACTIVE","INACTIVE") AS active_flag,

  CASE WHEN en_images = fr_images THEN CAST(en_images AS STRING)
    WHEN en_images <> fr_images THEN CONCAT(CAST(en_images AS STRING),"EN", "|", CAST(fr_images AS STRING),"FR") 
    WHEN en_images IS NULL AND fr_images IS NULL THEN "0" END AS image_count,

  GS1_name_en,
  CONCAT(UPPER(LEFT(GS1_name_fr,1)),LOWER(SUBSTRING(GS1_name_fr,2,LENGTH(GS1_name_fr)))) AS GS1_name_fr,
  GS1_desc_en,
  GS1_desc_fr,
  sdm_liam,
  supplier_name,
  supplier_filter,
  CASE WHEN pcs_liam IS NOT NULL THEN "APPROVED" ELSE "PENDING/NOT FOUND" END AS pcs_status,
  IF(sd.article_number IS NOT NULL,"Scheduled in all provinces",NULL) sd_flag,
  rtl_sales.* EXCEPT(liam),
  pcx_sales.* EXCEPT(liam),
  --CASE WHEN STRING_AGG(master_liam.liam) OVER (PARTITION BY master_liam.UPC) LIKE "%,%" THEN STRING_AGG(master_liam.liam) OVER (PARTITION BY master_liam.UPC) END AS multi_liam_upcs,
  --CASE WHEN STRING_AGG(master_liam.liam) OVER (PARTITION BY master_liam.article_number) LIKE "%,%" THEN STRING_AGG(master_liam.liam) OVER (PARTITION BY master_liam.article_number) END AS multi_liam_articles,
  CURRENT_DATETIME("EST") AS record_datetime
FROM master_liam
  LEFT JOIN navigation ON pcs_liam = navigation.liam
  LEFT JOIN dietarycallouts d on pcs_liam = d.liam
  LEFT JOIN nutr ON pcs_liam = nutr.liam
  LEFT JOIN ingr ON pcs_liam = ingr.liam
  LEFT JOIN s3 ON master_liam.article_number = s3.article_number
  LEFT JOIN assetful ON master_liam.liam = assetful.liam
  LEFT JOIN `ld-pcx-bia.Merch_PIM.PCX_ACTIVE_ARTICLE_STORES` active ON master_liam.article_number = active.article_number
  LEFT JOIN `ld-pcx-bia.Merch_PIM.PCX_IMAGE_CAROUSEL_DASH` i ON pcs_liam = i.liam
  LEFT JOIN gs1 ON master_liam.UPC = gs1.UPC
  LEFT JOIN sdm ON master_liam.UPC = sdm.UPC
  LEFT JOIN supplier ON master_liam.article_number = supplier.article_number
  LEFT JOIN `ld-pcx-bia.Merch_PIM.scheduled_drugs` sd ON master_liam.article_number = sd.article_number
  LEFT JOIN rtl_sales ON master_liam.liam = rtl_sales.liam
  LEFT JOIN pcx_sales ON master_liam.liam = pcx_sales.liam