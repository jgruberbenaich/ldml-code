WITH 
  vendor_exclusion AS (
    SELECT artcl_num
    FROM `ld-ds-bi-analytics-prod.bi_dw.vendor_determination` vd
    JOIN `ld-pcx-bia.Merch_PIM.SUPPLIER_ROLODEX` sr ON vd.vend_num = sr.vendor_number
    LEFT JOIN `ld-pcx-bia.Merch_PIM.SUPPLIER_SCORECARD_EXCLUSIONS` x ON vd.vend_num = x.vendor_number AND vd.artcl_num = x.article_number
    WHERE LOWER(category) LIKE "top%"
      AND x.article_number IS NULL
  ),

  mean AS (
    SELECT CONCAT(LTRIM(matnr,'0'),"_",meinh) AS liam,
      ean11 AS UPC
    FROM `ld-ds-bi-analytics-prod.cerebro_reporting.sap_ecc_mean`
    WHERE hpean = "X"
      AND LTRIM(matnr,'0') LIKE "2%"
  ),

  a AS (
  -- Find relevant SAP info for all PCX articles
  SELECT DISTINCT artcl_num, artcl_med_desc_en AS sap_name_en, mch_3_desc_en AS mch_3, mch_2_desc_en AS mch_2, mch_1_desc_en AS mch_1, mch_0_desc_en AS mch_0, mch_0_cd, ah_04_desc_en AS ah_4, ah_05_desc_en AS ah_5, brnd_cd AS brand,
 CASE 
    WHEN mch_3_cd IN ('M02','M03','M04','M05','M11','M12') -- Produce, Meat, Bakery, Deli, Seafood, HMR
    OR mch_2_cd IN ('M1022','M1023','M1024') -- COS>Dairy> Frozen, Bulk
    OR mch_1_cd IN ('M102101','M102102','M102103','M102104','M102105','M102106','M102107','M102108','M102109','M102110','M102116') -- COS>GROCERY> Breakfast, Hot Beverages & Accessories, Cold Beverages, Confectionary, Snacks, Baking, Canned, Meal Makers, Condiments, Salad Fixings, Confectionary - Seasonal
    OR mch_0_cd IN ('M10020104','M10020106',"M10250101","M10250103","M10250104","M10250105","M10250106","M10250107","M10250108","M10250109","M10250110","M10250111","M10250114","M10250116","M10250118","M10250120")-- COS>Baby> Infant Feeding, Infant Formula, COS>Natural Foods>Natural Foods> Active Lifestyle-Nat,Bakery-Natural Foods,Baking / Bulk-Natura,Beverages-Natural Fo,Breakfast-Natural Fo,Canned-Natural Foods,Condiments / Salad F,Confectionary / Bars,Dairy-Natural Foods,Frozen-Natural Foods,Hot Beverages-Natura,Meal Makers-Natural,Snacks-Natural Foods,Milk - Natural Foods
    OR ah_05_cd IN ("237711") -- COS>Baby>Baby-Natural Foods>Baby>Feeding
    THEN "food" ELSE "non-food" END AS food_flag,
  CASE 
    WHEN mch_3_cd IN ('M01','M06','M08','M13','M14','M99') -- REMOVES mch3 Apparel,Floral,Garden,Goods Not For Resale - GNFR,Other/Services,Pharmacy
    OR mch_2_cd IN ('M0940','M0944','M0945','M1504') -- REMOVES mch2 Eyewear,Gas Bar,Tobacco,Prestige Cosmetics
    OR mch_1_cd IN ('M150304','M074202','M074201','M074208','M074209','M074205','M074109','M074105','M074107','M092601') -- REMOVES mch1 Jewellery & Fashion,Gaming,Movies,Photo Image,Portraits,Reading,Cards And Wrap,Dollar Shop,Hardware/Automotive, Spirits
    OR mch_0_cd IN ('M10380316','M12360103','M07420402','M07420403','M07420404','M07420405','M07420301','M07420302','M07420303','M07420305','M07420306','M07420307','M07420304','M07410415','M07411001',  'M07411007') -- REMOVES mch0 Home Health Care,Instore Coffee Shop,Cameras,Digital Hardlines,Computers & Accessor,Printers & Supplies,Audio Accessories,Dvd/Bluray,Home Theatre,Personal Audio,Phones,Clock Radios&,Televisions&AV Acces,Ipod,Front End Bags,Calendars-Seasonal,Seasonal Other
    OR ah_05_cd IN ('256541') -- REMOVES INEDIBLE DECORATIONS FROM IN-STORE BAKERY
    THEN "MCH Not Actively Enriched" ELSE "Actively Enriched" END AS mch_type
  FROM `lt-dia-lake-prd-consume.product.article_curr`
  LEFT JOIN vendor_exclusion USING(artcl_num)
  WHERE brnd_ty_cd = "2" -- exclude control brands
    AND vendor_exclusion.artcl_num IS NULL -- exclude articles from top vendors
  ),

PCS AS (
  SELECT liam,
    article_number,
    brand.name_en AS brand_en,
    brand.brand_displayable,
    brand.sub_brand.name_en AS subbrand_en,
    name_en AS pcs_name_en,
    description_en AS pcs_desc_en,
    CONCAT(IF(attributes.items_per_package>1,CONCAT(CAST(attributes.items_per_package AS STRING),"x"),""),CAST(attributes.item_size AS STRING), attributes.item_size_uom) AS product_size,
  FROM `ld-ds-bi-analytics-prod.product_catalog.products`
  WHERE status = "APPROVED"
    AND liam LIKE "2%"
    AND (LENGTH(`ld-pcx-bia.Merch_PIM`.REMOVE_HTML(description_en))<100 OR description_en IS NULL) -- Descriptions shorter than 100 characters after removing HTML tags
    ),

pcx_sales AS (
  SELECT CONCAT(article_id,"_",sales_uom_cd) AS liam,
    SUM(sales_amt) AS L12W_PCX_sales,
 FROM `ld-ds-bi-analytics-prod.bi_reporting.sl_trans_qlfy_ecom_dly`
 WHERE transaction_dt > CURRENT_DATE()-84 -- REQUIRED to put a transaction_dt filter on
  AND article_id LIKE "2%" -- PCX articles only
  AND article_acct_assn_grp_cd IN ('01','21') -- ALWAYS use this filter on this table
  AND ecom_ind IN ('4','5') -- ALWAYS exclude JoeFresh/ShipFromStore channels
 GROUP BY 1
  ),

rtl_sales AS(
  SELECT CONCAT(artcl_num,"_",sl_uom_cd) AS liam,
    SUM(prrtd_pstd_sl_amt) AS L12W_rtl_sales,
FROM `lt-dia-lake-prd-consume.financial_reporting.sales_lcl_store_article_dly`
WHERE trans_dt > CURRENT_DATE()-84 -- REQUIRED TO put a trans_dt filter
  AND artcl_acct_assn_grp_cd IN ('01','21') -- ALWAYS use this filter on this table
  AND artcl_num LIKE "2%" -- PCX articles only
GROUP BY 1
),

gs1 AS (
  SELECT DISTINCT gtin_cd AS UPC,
  TRIM(CONCAT(COALESCE(subbrnd_eng_nm,"")," ",COALESCE(fnc_eng_nm,"")," ",COALESCE(var_eng_desc,""))) AS english,
  TRIM(CONCAT(COALESCE(subbrnd_fr_nm,"")," ",COALESCE(fnc_fr_nm,"")," ",COALESCE(var_fr_desc,""))) AS french,
  addedfeat_and_bnft_eng_desc AS addedfeaturesandbenefitsenglish,
  brnd_own_prod_mkt_eng_msg AS brandownerproductmarketingmessageenglish
  FROM `lt-dia-lake-prd-consume.product.ecommerce_content_curr`
)

SELECT mean.UPC, pcs.liam, article_number, sap_name_en,
  brand_en, 
  brand_displayable, 
  subbrand_en, 
  pcs_name_en, 
  pcs_desc_en,
  MCH_3, MCH_2, MCH_1, MCH_0, mch_0_cd,
  total_stores, 
  L12W_PCX_sales,
  L12W_RTL_sales,
  addedfeaturesandbenefitsenglish,
  brandownerproductmarketingmessageenglish,
  food_flag,
  mch_type,
FROM pcs 
JOIN mean USING(liam)
JOIN a ON article_number = artcl_num
JOIN `ld-pcx-bia.Merch_PIM.PCX_ACTIVE_ARTICLE_STORES` USING(article_number)
LEFT JOIN pcx_sales ON pcs.liam = pcx_sales.liam
LEFT JOIN rtl_sales ON pcs.liam = rtl_sales.liam
LEFT JOIN gs1 ON mean.upc = gs1.upc
ORDER BY L12W_rtl_sales DESC, L12W_pcx_sales DESC, total_stores DESC