WITH
mara AS (
  SELECT DISTINCT
    LTRIM(matnr,'0') AS article_number,
    ersda AS sap_created_date,
    bismt AS old_article_number,
    meins AS article_primary_uom,
    ean11 AS article_primary_barcode,
  FROM `ld-ds-bi-analytics-prod.cerebro_reporting.sap_ecc_mara`
  WHERE DELETED_FLAG IS FALSE
  ),

mean AS (
  SELECT 
    LTRIM(matnr,'0') AS article_number,
    CONCAT(LTRIM(matnr,'0'),"_",meinh) AS liam,
    meinh AS uom,
    ARRAY_AGG(STRUCT(
      ean11 AS sap_barcode,
      hpean="X" AS liam_primary_barcode,
      eantp AS barcode_type,
      eantp_description AS barcode_description) ORDER BY hpean DESC, eantp, ean11) AS mean
  FROM `ld-ds-bi-analytics-prod.cerebro_reporting.sap_ecc_mean`
  LEFT JOIN `ld-pcx-bia.jongrub.eantp_descriptions_gsheet` USING(eantp)
  WHERE 1=1
    AND DELETED_FLAG IS FALSE
    AND STARTS_WITH(LTRIM(matnr,'0'),'2')
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
      vendor.lcl_store_id AS store_number,
      banner,
      division) IGNORE NULLS ORDER BY vendor.lcl_store_id) AS st
  FROM `ld-ds-bi-analytics-prod.product_catalog.upcs`
    LEFT JOIN UNNEST(upcs) AS upc
    LEFT JOIN st ON LPAD(vendor.lcl_store_id,4,'0') = store
  GROUP BY ALL
  ),

pcs AS (
  SELECT liam,
    status AS pcs_status,
  ARRAY_AGG(STRUCT(
    pcs_barcode,
    st)) AS pcs
FROM pcs_prep
FULL JOIN `ld-ds-bi-analytics-prod.product_catalog.products` p USING(liam)

GROUP BY ALL
)


SELECT *
FROM mara
LEFT JOIN mean USING(article_number)
LEFT JOIN pcs USING(liam)
