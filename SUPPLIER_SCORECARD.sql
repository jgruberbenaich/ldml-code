WITH v AS(
  --Identifies vendor-article relationships
  SELECT rolodex_name, vd.artcl_num AS article_number, 
    STRING_AGG(CAST(LTRIM(vd.vend_num,'0') AS STRING),"|") AS vendor_number
  FROM `ld-ds-bi-analytics-prod.bi_dw.vendor_determination` vd
  JOIN `ld-pcx-bia.Merch_PIM.SUPPLIER_ROLODEX` ON vd.vend_num = vendor_number
  LEFT JOIN `ld-pcx-bia.Merch_PIM.SUPPLIER_SCORECARD_EXCLUSIONS` x ON vd.artcl_num = x.article_number AND LTRIM(vd.vend_num,'0')=LTRIM(x.vendor_number,'0')
  WHERE x.article_number IS NULL
    #AND rolodex_name LIKE "Mondelez"
  GROUP BY ALL),

b AS (
  --All national brands and brand info
    SELECT DISTINCT brand.code,
      IF(brand.brand_displayable = TRUE,brand.name_en,NULL) AS brand,
    FROM `ld-ds-bi-analytics-prod.product_catalog.products`
    WHERE 1=1
      AND brand.control_brand = FALSE
      AND status = "APPROVED"
      AND liam LIKE "2%"
      ),

a AS ( 
  -- Pull in fields for relevant MCHs for PCX Enrichment, identify food articles, SAP brand
  SELECT article_number, artcl_med_desc_en,
  -- Identify food items that should have nutrition data
CASE WHEN 
  mch_3_cd IN ('M02','M03','M04','M05','M11','M12') -- Produce, Meat, Bakery, Deli, Seafood, HMR
  OR mch_2_cd IN ('M1022','M1023','M1024') -- COS>Dairy> Frozen, Bulk
  OR mch_1_cd IN ('M102101','M102102','M102103','M102104','M102105','M102106','M102107','M102108','M102109','M102110','M102116') -- COS>GROCERY> Breakfast, Hot Beverages & Accessories, Cold Beverages, Confectionary, Snacks, Baking, Canned, Meal Makers, Condiments, Salad Fixings, Confectionary - Seasonal
  OR mch_0_cd IN ('M10020104',"M10250101","M10250103","M10250104","M10250105","M10250106","M10250107","M10250108","M10250109","M10250110","M10250111","M10250114","M10250116","M10250118","M10250120")-- COS>Baby> Infant Feeding, COS>Natural Foods>Natural Foods> Active Lifestyle-Nat,Bakery-Natural Foods,Baking / Bulk-Natura,Beverages-Natural Fo,Breakfast-Natural Fo,Canned-Natural Foods,Condiments / Salad F,Confectionary / Bars,Dairy-Natural Foods,Frozen-Natural Foods,Hot Beverages-Natura,Meal Makers-Natural,Snacks-Natural Foods,Milk - Natural Foods
  OR ah_05_cd IN ("237711") -- COS>Baby>Baby-Natural Foods>Baby>Feeding
  THEN TRUE END AS food_item,
      mch_2_desc_en, mch_1_desc_en, mch_0_desc_en,
      bse_uom_cd,
      brnd_cd,
      IF(b.code IS NULL, brnd_desc_en,brand) AS brand -- If brand code is found on an approved product in PCS, use PCS brand name. If not, use sap brand description.
      FROM `lt-dia-lake-prd-consume.product.article_curr`
      JOIN `ld-pcx-bia.Merch_PIM.PCX_ACTIVE_ARTICLE_STORES` ON artcl_num = article_number
      LEFT JOIN b ON brnd_cd = code
      WHERE brnd_ty_cd = "2" --National Brand products
        -- Filter out any articles in TOYS that contain multivariants and can't be sold online
        AND NOT (mch_1_cd in ('M074207') and trim(lower(artcl_med_desc_en)) LIKE '% ast')
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
        -- Filter out any articles in in Seasonal (MCH1 = M074110) that end in whole word “AST”, "ASST", "EN" 
        AND NOT (mch_1_cd in ('M074110') and trim(lower(artcl_med_desc_en)) LIKE '% ast')
        AND NOT (mch_1_cd in ('M074110') and trim(lower(artcl_med_desc_en)) LIKE '% asst')
        AND NOT (mch_1_cd in ('M074110') and trim(lower(artcl_med_desc_en)) LIKE '% en %')
        -- Filter out any articles in HMR Ready to Eat (MCH0 = M12360101) that contains: 
        AND NOT (mch_0_cd in ('M12360101') and trim(lower(artcl_med_desc_en)) LIKE '%menu%')  --the word “Menu”,
        AND NOT (mch_0_cd in ('M12360101') and trim(lower(artcl_med_desc_en)) LIKE '%entree%side%') --both (“entree” and “side” in the description, eg. “Entree + 2 Sides”)
        AND NOT (mch_0_cd in ('M12360101') and trim(lower(artcl_med_desc_en)) LIKE '%combo%') --the word “Combo”
        -- Filter out articles which do not correspond to sellable products
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
  ),

mean AS (
  SELECT CONCAT(LTRIM(matnr,'0'),"_",meinh) AS liam,
    ean11 AS UPC
  FROM `ld-ds-bi-analytics-prod.cerebro_reporting.sap_ecc_mean`
  WHERE deleted_flag = FALSE
    AND LTRIM(matnr,'0') LIKE "2%" -- PCX articles only
    AND hpean = "X" -- Primary UPC only
    ),

n AS (
  -- Extract nutritional fact table info for each LIAM
  SELECT liam, STRING_AGG(n.value) AS nutrients
  FROM `ld-ds-bi-analytics-prod.product_catalog.products` p
    JOIN b ON p.brand.code = b.code
    ,UNNEST(nutrition.recipes) as nr    
    ,UNNEST(nr.nutrients) n
  WHERE 1=1
    AND status = "APPROVED"
    AND article_number LIKE "2%"
  GROUP BY ALL
  ),

nc AS (
  -- Extract Site Navigation Breadcrumbs (navigation categories) for each LIAM
  SELECT liam, STRING_AGG(n.en, ", ") AS site_nav_breadcrumbs
  FROM `ld-ds-bi-analytics-prod.product_catalog.products` p
    JOIN b ON p.brand.code = b.code
      ,UNNEST (nav_categories) as nc, UNNEST(nc.nav_category) AS n
  WHERE 1=1
    AND status = "APPROVED"
    AND article_number LIKE "2%"
  GROUP BY ALL
  ),


ing AS (
  -- Extract ingredients information for each LIAM
  SELECT liam,
    STRING_AGG(nr.ingredients.en) AS ingredients_en, 
    STRING_AGG(nr.ingredients.fr) AS ingredients_fr
  FROM `ld-ds-bi-analytics-prod.product_catalog.products` p
  JOIN b ON p.brand.code = b.code
  ,UNNEST(nutrition.recipes) as nr
  WHERE 1=1
    AND status = "APPROVED"
    AND article_number LIKE "2%"
    AND REGEXP_CONTAINS(UPPER(uom),r'EA|KG|C\d')
  GROUP BY ALL),

p AS (
  -- Extract general PCS fields for each LIAM
  SELECT liam,article_number,name_en, name_fr,description_en, description_fr, status, 
    IF(p.brand.sub_brand.sub_brand_displayable = TRUE,p.brand.sub_brand.name_en,NULL) AS sub_brand,
    CONCAT(
      IF(attributes.items_per_package >1, CONCAT(CAST(attributes.items_per_package AS STRING),"x "),""),
      CAST(ROUND(attributes.item_size,2) AS STRING)," ",
      attributes.item_size_uom) AS product_size
    FROM `ld-ds-bi-analytics-prod.product_catalog.products` p
      JOIN b ON p.brand.code = b.code
    WHERE status = "APPROVED"
      AND liam LIKE "2%"
      AND REGEXP_CONTAINS(UPPER(uom),r'EA|KG|C\d')
    ),

  stores AS (
    -- Find list of PCX-enabled stores
  SELECT DISTINCT store_number, store_division
  FROM `ld-ds-bi-analytics-prod.bi_reporting.pcx_stores`
  WHERE LOWER(TRIM(banner_name)) NOT IN ('unknown','joe fresh','tt','real canadian liquor store') --  Exclude TT, Unknown, JF,RCLS
    AND CHAR_LENGTH(store_number) <= 4
    AND og_close_date > CURRENT_DATE()
    AND active_date <= CURRENT_DATE()),

  r AS ( 
  -- Find all articles which have retail sales in L12W at PCX-enabled stores
  SELECT CONCAT(artcl_num,"_",sl_uom_cd) AS liam,
    artcl_num,
    ROUND(SUM(IF(store_division = 'B2B',ROUND(prrtd_pstd_sl_amt,2),0)),2) AS wholesale_L12W,
    ROUND(SUM(ROUND(prrtd_pstd_sl_amt,2)),2) AS total_L12W
  FROM `lt-dia-lake-prd-consume.financial_reporting.sales_lcl_store_article_dly`
    JOIN stores ON LTRIM(store_number,'0') = LTRIM(site_num,'0')
  WHERE trans_dt > CURRENT_DATE()-84 -- Required to filter on this field
    AND artcl_acct_assn_grp_cd IN ('01','21') -- ALWAYS use this filter on this table
  GROUP BY ALL
  HAVING SUM(prrtd_pstd_sl_amt)>100),

  s3_images AS (
    -- Check S3 for images
    SELECT article_number, url AS image_url
    FROM `ld-ds-bi-analytics-prod.bi_dw.pcx_product_image_avalibility`
    WHERE record_current_flag = 1
      AND is_image_available = TRUE
  ),

  pcs_images AS ( 
    -- Pull all EN image data
  SELECT DISTINCT SPLIT(liam,"_")[OFFSET(0)] AS article_number, en_images, fr_images, EN_1, EN_2, EN_3, EN_4, EN_5, EN_6, EN_7, EN_8, EN_9, EN_10
  FROM `ld-pcx-bia.Merch_PIM.PCX_IMAGE_CAROUSEL_EXCEL`
  JOIN v ON SPLIT(liam,"_")[OFFSET(0)] = v.article_number),

prep AS (SELECT 
  v.*,
  a.mch_2_desc_en AS AISLE, 
  a.mch_1_desc_en AS CATEGORY, 
  a.mch_0_desc_en AS SUBCATEGORY,
  CASE WHEN SAFE_DIVIDE(wholesale_L12W, total_L12W) >= 0.5 THEN "Wholesale" ELSE "Retail" END AS wholesale_item,
  CAST(v.article_number AS STRING) AS article,
  UPC,
  r.liam AS article_uom,
  artcl_med_desc_en AS sapname,
  IF(p.status IS NULL OR p.status = "PENDING", "✘","✔") AS online_status,
  IF(s3_images.image_url IS NULL, "✘","✔") AS image_available,
  CASE WHEN p.name_en IS NULL THEN "✘"
    WHEN UPPER(p.name_en) = p.name_en AND (p.status IS NULL OR p.status = "PENDING") THEN "✘"
    ELSE "✔" END AS name_en_available, 
  CASE WHEN p.name_fr IS NULL THEN "✘"
    WHEN UPPER(p.name_fr) = p.name_fr AND (p.status IS NULL OR p.status = "PENDING") THEN "✘"
    ELSE "✔" END AS name_fr_available,
  IF(description_en IS NOT NULL,CHAR_LENGTH(`ld-pcx-bia.Merch_PIM`.REMOVE_HTML(description_en)),0) AS desc_en_len,
  IF(description_fr IS NOT NULL,CHAR_LENGTH(`ld-pcx-bia.Merch_PIM`.REMOVE_HTML(description_fr)),0) AS desc_fr_len,  
  CASE WHEN n.nutrients IS NOT NULL AND LENGTH(n.nutrients) > 2 AND food_item IS NOT NULL THEN "✔"
    WHEN n.nutrients IS NULL and food_item IS NOT NULL THEN "✘"
    ELSE "N/A" END AS nft_available,
  CASE WHEN ingredients_en IS NOT NULL AND LENGTH(ingredients_en) > 2 AND food_item IS NOT NULL THEN "✔"
    WHEN ingredients_en IS NULL and food_item IS NOT NULL THEN "✘"
    ELSE "N/A" END AS ing_en_available,
  CASE WHEN ingredients_fr IS NOT NULL AND LENGTH(ingredients_fr) > 2 AND food_item IS NOT NULL THEN "✔"
    WHEN ingredients_fr IS NULL and food_item IS NOT NULL THEN "✘"
    ELSE "N/A" END AS ing_fr_available,
  CASE WHEN en_images IS NULL THEN 0
    ELSE en_images END AS image_count,
  pcs_images.* EXCEPT(article_number),
  a.brand,
  p.product_size,
  p.name_en AS product_title_en,
  p.name_fr AS product_title_fr,
  p.description_en AS product_desc_en,
  p.description_fr AS product_desc_fr,
  nc.site_nav_breadcrumbs,
  total_L12W
FROM v
  JOIN r ON v.article_number = r.artcl_num
  JOIN a on CAST(v.article_number AS STRING) = a.article_number
  LEFT JOIN mean ON r.liam = mean.liam
  LEFT JOIN p ON r.liam = p.liam
  LEFT JOIN n ON p.liam = n.liam
  LEFT JOIN nc ON p.liam = nc.liam
  LEFT JOIN ing ON p.liam = ing.liam
  LEFT JOIN s3_images ON v.article_number = s3_images.article_number
  LEFT JOIN pcs_images ON v.article_number = pcs_images.article_number
  LEFT JOIN `ld-pcx-bia.Merch_PIM.scheduled_drugs` s3 ON v.article_number = s3.article_number
WHERE s3.article_number IS NULL) -- Exclude Schedule 3 products

SELECT DISTINCT rolodex_name,
  vendor_number,
  aisle,
  category,
  subcategory,
  article,
  upc,
  article_uom,
  sapname,
  wholesale_item,
  CASE WHEN en_images = 0 OR en_images IS NULL OR name_en_available = "✘" OR name_fr_available = "✘" THEN "Missing required information"
       WHEN nft_available = "✘" OR ing_en_available = "✘" OR ing_fr_available = "✘" OR desc_en_len < 300 OR desc_fr_len <300 OR GREATEST(en_images, fr_images) <3 THEN "Does not meet certain enrichment criteria"
       ELSE "Meets all enrichment criteria"
       END AS enrichment_summary,

  CASE WHEN en_images = 0 OR en_images IS NULL OR name_en_available = "✘" OR name_fr_available = "✘" THEN 0
       WHEN nft_available = "✘" OR ing_en_available = "✘" OR ing_fr_available = "✘" OR desc_en_len < 300 OR desc_fr_len <300 OR GREATEST(en_images, fr_images) <3 THEN 50
       ELSE 100
       END AS enrichment_score,
  image_count,
  name_en_available,
  name_fr_available,
  desc_en_len,
  desc_fr_len,
  nft_available,
  ing_en_available,
  ing_fr_available,
  online_status,
  en_1,
  en_2,
  en_3,
  en_4,
  en_5,
  en_6,
  en_7,
  en_8,
  en_9,
  en_10,
  brand,
  product_size,
  product_title_en,
  product_title_fr,
  product_desc_en,
  product_desc_fr,
  site_nav_breadcrumbs,
FROM prep
ORDER BY rolodex_name, brand, aisle, category, subcategory, enrichment_score, article_uom