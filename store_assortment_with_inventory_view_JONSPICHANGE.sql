 -- assortment section --
 
 WITH
    DS AS (
    SELECT
      assortment_run_date,
      st.division,
      --st.banner,
      --New Banner Logic:
      CASE
        WHEN ao.store_number IN ('479', '2660', '2663', '2668', '6799', '7522') THEN 'ICM'
        WHEN ao.store_number IN ('7154') THEN 'LOB - MFC'
        WHEN ao.store_number IN ('1629', '1652', '1808', '1820', '1821', '1822', '1872', '4429', '7155', '7309', '7491', '7494', '7534') -- Loblaws West stores that are listed as YIGW
      OR st.banner LIKE 'LOB%' THEN 'LOB'
        WHEN st.ash_2_name = 'Valu-mart' THEN 'VM'
        ELSE st.banner
    END
      banner,
      CASE
        WHEN ao.store_number IN ('479', '2660', '2663', '2668', '6799', '7522') THEN 'independentcitymarket'
        WHEN ao.store_number IN ('1629','1652','1808','1820','1821','1822','1872','4429','7155','7309','7491','7494','7534') -- Loblaws West stores that are listed as YIGW
         OR st.banner LIKE 'LOB%' THEN 'loblaws'
        WHEN st.banner = 'RCSO' THEN 'realcanadiansuperstore'
        WHEN st.banner = 'RCSW' THEN 'realcanadiansuperstore'
        WHEN st.banner = 'ZEHRS' THEN 'zehrs'
        WHEN st.banner = 'NF' THEN 'nofrills'
        WHEN st.banner = 'MAXI' THEN 'maxi'
        WHEN st.ash_2_name = 'Valu-mart' THEN 'valumart'
        WHEN st.banner = 'YIGO' THEN 'yourindependentgrocer'
        WHEN st.banner = 'YIGW' THEN 'yourindependentgrocer'
        WHEN st.banner = 'YIGA' THEN 'yourindependentgrocer'
        WHEN st.banner = 'RCWC' THEN 'wholesaleclub'
        WHEN st.banner = 'RASS' THEN 'atlanticsuperstore'
        WHEN st.banner = 'FORT' THEN 'fortinos'
        WHEN st.banner = 'PRO' THEN 'provigo'
        WHEN st.banner = 'DOM' THEN 'newfoundlandgrocerystores'
        ELSE ""
     END AS Banner_Name_URL,
     st.province,
     ao.store_number,
     st.store_name,
     mch_2_desc_english,
     mch_0_desc_english,
     ao.mch_0_code,
     article_uom,
     article_desc_english,
     passfail,
     passfail_reason
    FROM `ld-ds-bi-analytics-prod.assortment.assortment_output` ao
    LEFT JOIN
      `ld-pcx-bia.dim.stores_flip`st
    ON LTRIM(ao.store_number,'0') = st.store_number
    LEFT JOIN
      `ld-ds-bi-analytics-prod.bi_reporting.pcx_teradata_articles` art
    ON SPLIT(article_uom,'_')[SAFE_ORDINAL(1)] = art.article_number
    WHERE
      banner NOT IN ('EF')
      AND assortment_run_date >= CURRENT_DATE("EST") - 3 -- Get article/store for last 3 assortment runs
      AND BANNER IS NOT NULL
      AND og_close_date > CURRENT_DATE("EST")
    ),

    assortment AS (
    SELECT
      DS.*,
      CASE
        WHEN is_assorted =FALSE THEN 'Fail'
        WHEN is_assorted =TRUE THEN 'Pass'
        ELSE NULL
    END
      AS PCS_result,
      status
    FROM DS
    LEFT JOIN `ld-ds-bi-analytics-prod.product_catalog.offers` ON (vendor.store_id,LIAM) = (Ds.store_number,article_uom)
    WHERE
      DATE(valid_to) > CURRENT_DATE("EST")
    ),

-- inventory section --

    uom AS (
    SELECT
      storeID,
      articleID,
      CONCAT(articleID,"_",UOM) AS inv_liam,
      conversion_factor,
    FROM
      `ld-ds-bi-analytics-prod.assortment.InventoryUOMs`
    QUALIFY
      ROW_NUMBER() OVER(PARTITION BY storeID, articleID, UOM ORDER BY insertTimestamp DESC) = 1 -- Only consider most recent record of conversion_factor for that liam/store
    ),

    inv AS (
    SELECT
      LTRIM(ARTICLE_NUM,'0') AS inv_article,
      inv_liam,
      LTRIM(SITE,'0') AS inv_site,
      CURRENT_STOCK,
      DISMM,
      conversion_factor,
      SAFE_MULTIPLY(IFNULL(CURRENT_STOCK,0),IFNULL(conversion_factor,0)) AS converted_units,
      MARD_TIMESTAMP,
      DATE(PART_TIMESTAMP) AS inventory_run_date
    FROM `ld-ds-bi-analytics-prod.inventory.inventory`
    JOIN uom ON LTRIM(ARTICLE_NUM,'0') = LTRIM(articleID,'0') AND LTRIM(SITE,'0') = LTRIM(storeID,'0')
    
    WHERE
      DATE(PART_TIMESTAMP) >= CURRENT_DATE("EST") - 60 -- Check 60 days worth of data
    QUALIFY ROW_NUMBER() OVER(PARTITION BY ARTICLE_NUM, SITE ORDER BY MARD_TIMESTAMP DESC) = 1 -- Get the most recent inventory record of article for each store
    ),

    pi AS (
      SELECT DISTINCT 
        LTRIM(matnr,'0') AS article,
        LTRIM(werks,'0') AS store,
        isAccuratePI = 1 AS is_PI
      FROM `ld-ds-bi-analytics-prod.assortment.sap_article_info`
    )

  SELECT
    a.*,
    pi.is_PI,
    i.MARD_TIMESTAMP AS most_recent_inventory_change_ts,
    i.CURRENT_STOCK AS most_recent_current_stock_value,
    i.conversion_factor AS most_recent_conversion_factor,
    i.converted_units AS most_recent_converted_units,
    CASE -- Unclear how other QTY fields are factored into stock badging
      WHEN is_PI IS FALSE THEN "In Stock (PI Not Required)" -- Item is not on PI, assume it is in stock if it's offered
      WHEN is_PI IS NULL THEN "Unknown"
      WHEN CURRENT_STOCK IS NULL THEN "Unknown"
      WHEN CURRENT_STOCK <= 0 THEN "Out of Stock"
      WHEN CURRENT_STOCK <= 3 THEN "Low Stock"
      WHEN CURRENT_STOCK > 3 THEN "In Stock"
    END AS most_recent_stock_badge,
  FROM assortment AS a
  LEFT JOIN inv AS i 
    ON a.store_number = i.inv_site 
    AND a.article_uom = i.inv_liam
  LEFT JOIN  pi
    ON SPLIT(article_uom,"_")[OFFSET(0)] = article
     AND store_number = store