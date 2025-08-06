CREATE OR REPLACE TABLE `ld-pcx-bia.jongrub.barcode_dashboard_tbl` 
CLUSTER BY liam
AS (
WITH
mara AS (
  SELECT DISTINCT
    LTRIM(matnr,'0') AS article_number,
    ersda AS sap_created_date,
    bismt AS old_article_number,
    meins AS article_primary_uom,
    ean11 AS article_primary_barcode,
    artcl_med_desc_en AS sap_name_en
  FROM `ld-ds-bi-analytics-prod.cerebro_reporting.sap_ecc_mara`
  LEFT JOIN `lt-dia-lake-prd-consume.product.article_curr` ON LTRIM(matnr,'0') = artcl_num
  WHERE 1=1
    AND DELETED_FLAG IS FALSE
    AND STARTS_WITH(LTRIM(matnr,'0'),'2')
  QUALIFY ROW_NUMBER() OVER(PARTITION BY matnr ORDER BY PARTITION_timestamp DESC, timestamp DESC) = 1
  ),

mean_prep AS (
  SELECT 
    LTRIM(matnr,'0') AS article_number,
    meinh AS uom,
    CONCAT(LTRIM(matnr,'0'),"_",meinh) AS liam,
    ean11 AS barcode,
    hpean="X" AS liam_primary_barcode,
    eantp AS barcode_type,
    eantp_description AS barcode_type_desc
  FROM `ld-ds-bi-analytics-prod.cerebro_reporting.sap_ecc_mean`
  LEFT JOIN `ld-pcx-bia.jongrub.eantp_descriptions_gsheet` USING(eantp)
  WHERE 1=1
    AND DELETED_FLAG IS FALSE
    AND STARTS_WITH(LTRIM(matnr,'0'),'2')
  QUALIFY ROW_NUMBER() OVER(PARTITION BY CONCAT(LTRIM(matnr,'0'),"_",meinh),ean11 ORDER BY rec_cre_tms DESC, PARTITION_timestamp DESC, timestamp DESC) = 1
  ORDER BY liam,liam_primary_barcode DESC, barcode_type_desc, barcode
  ),
  
mean AS (
  SELECT 
    article_number,
    uom,
    liam,
    ARRAY_AGG(STRUCT(
      barcode,
      liam_primary_barcode,
      barcode_type,
      barcode_type_desc) IGNORE NULLS ORDER BY liam_primary_barcode DESC, barcode_type, barcode) AS mean
  FROM mean_prep
  GROUP BY ALL
  ORDER BY 1,2,3
  ),

st AS (
  SELECT DISTINCT 
    store_division AS division,
    store_banner_code AS banner,
    LPAD(hub_store_number,4,'0') AS store
  FROM `ld-ds-bi-analytics-prod.bi_reporting.pcx_stores`
  WHERE LOWER(TRIM(banner_name)) NOT IN ('unknown','joe fresh','tt','real canadian liquor store')
    AND og_close_date > CURRENT_DATE()
    AND active_date <= CURRENT_DATE()
  ),

pcs_prep AS (
  SELECT
    liam,
    upc AS pcs_barcode,
    ARRAY_AGG(STRUCT(
      vendor.lcl_store_id AS store_number
      #,banner,
      #division
      ) IGNORE NULLS ORDER BY vendor.lcl_store_id) AS st
  FROM `ld-ds-bi-analytics-prod.product_catalog.upcs`
    LEFT JOIN UNNEST(upcs) AS upc
    LEFT JOIN st ON LPAD(vendor.lcl_store_id,4,'0') = store
  WHERE STARTS_WITH(liam,'2')
  GROUP BY ALL
  ),

pcs AS (
  SELECT liam,
    IFNULL(status,"PENDING/NOT FOUND") AS pcs_status,
  ARRAY_AGG(STRUCT(
    pcs_barcode,
    st)) AS pcs
FROM pcs_prep
FULL JOIN `ld-ds-bi-analytics-prod.product_catalog.products` p USING(liam)
GROUP BY ALL
),

sc AS (
  SELECT TRIM(CONCAT(artcl_num,"_",sl_uom_cd)) AS liam,
    ARRAY_AGG(STRUCT(
      scan_cd,
      scan_cat_cd,
      eantp_description AS scan_cat_description)) AS sc
  FROM `ld-ds-bi-analytics-prod.bi_dw.pcx_teradata_article_scan_codes`
  LEFT JOIN `ld-pcx-bia.jongrub.eantp_descriptions_gsheet` ON eantp = scan_cat_cd
  WHERE 1=1
    AND STARTS_WITH(artcl_num,'2')
    AND curr_ind = "Y"
  GROUP BY ALL
  )



SELECT *, CURRENT_DATETIME('EST') AS runtime
FROM mara
FULL JOIN mean USING(article_number)
FULL JOIN pcs USING(liam)
FULL JOIN sc USING(liam)
)