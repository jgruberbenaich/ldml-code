WITH
  st AS (
    SELECT DISTINCT 
      store_division AS division,
      store_banner_code AS banner,
      domain_name AS Banner_Name_URL, -- site domain to be used for PDP link
      province,
      store_number,
      nsl_store_name,
      #platforms_enabled AS fulfillment_types_array,
      #ARRAY_TO_STRING(platforms_enabled,"\n") AS fulfillment_types_string
    FROM `ld-ds-bi-analytics-prod.bi_reporting.pcx_stores` st
    #LEFT JOIN `ld-pcx-bia.jongrub.pcx_stores_fulfillment_types` ft ON LTRIM(st.store_number,'0') = LTRIM(ft.store_num,'0') 
    WHERE 1=1
      AND IFNULL(store_banner_code,'UNKNOWN') NOT IN ('EF','JF','NN','RAPID','RCLS','TT','UNKNOWN')
      AND store_close_date > CURRENT_DATE("EST")  -- Ignore stores that are permanently closed
      AND LENGTH(store_number) <= 4
    GROUP BY ALL
    ),
-- assortment section -- 
  ao AS (
    SELECT DISTINCT
      assortment_run_date,
      ao.store_number,
      st.* EXCEPT(store_number),
      mch_2_desc_english,
      mch_0_desc_english,
      ao.mch_0_code,
      article_uom,
      SPLIT(article_uom,'_')[OFFSET(0)] AS article,
      article_desc_english,
      passfail,
      passfail_reason
    FROM `ld-ds-bi-analytics-prod.assortment.assortment_output` ao
    JOIN st ON LTRIM(ao.store_number,'0') = LTRIM(st.store_number,'0') -- inner join to only show stores which are still open
    LEFT JOIN `ld-ds-bi-analytics-prod.bi_reporting.pcx_teradata_articles` art ON SPLIT(article_uom,'_')[SAFE_ORDINAL(1)] = art.article_number
    WHERE 1=1
      AND assortment_run_date > DATE_SUB(CURRENT_DATE("EST"), INTERVAL 3 DAY) -- Get article/store FOR LAST 3 DAYS
    ),
    
  pcs_offers AS (
    SELECT DISTINCT 
      liam,
      vendor.store_id,
      CASE WHEN pt.status = "APPROVED" 
        AND IFNULL(vendor.pcx_enabled,FALSE) IS TRUE 
        AND IFNULL(is_assorted,FALSE) IS TRUE 
        AND CURRENT_DATE('EST') BETWEEN IFNULL(DATE(ofr.valid_from),'9999-12-31') AND IFNULL(DATE(ofr.valid_to),'2000-01-01') 
        AND CURRENT_DATE('EST') BETWEEN IFNULL(DATE(price.valid_from),'9999-12-31') AND IFNULL(DATE(price.valid_to),'2000-01-01') 
        THEN "Pass"
        ELSE "Fail"
        END AS pcs_result,
      ARRAY_TO_STRING(SPLIT(
        CASE WHEN IFNULL(pt.status,"PENDING") <> "APPROVED" THEN "F - LIAM Not Enriched," ELSE "" END ||
        CASE WHEN IFNULL(vendor.pcx_enabled,FALSE) IS FALSE THEN "F - Store Not PCX Enabled," ELSE "" END ||
        CASE WHEN IFNULL(is_assorted,FALSE) IS FALSE THEN "F - Not Assorted," ELSE "" END ||
        CASE WHEN CURRENT_DATE('EST') NOT BETWEEN IFNULL(DATE(ofr.valid_from),'9999-12-31') AND IFNULL(DATE(ofr.valid_to),'2000-01-01') THEN "F - No Valid Offer," ELSE "" END ||
        CASE WHEN CURRENT_DATE('EST') NOT BETWEEN IFNULL(DATE(price.valid_from),'9999-12-31') AND IFNULL(DATE(price.valid_to),'2000-01-01') THEN "F - No Valid Price" ELSE "" END ||
        CASE WHEN pt.status = "APPROVED" 
          AND IFNULL(vendor.pcx_enabled,FALSE) IS TRUE 
          AND IFNULL(is_assorted,FALSE) IS TRUE 
          AND CURRENT_DATE('EST') BETWEEN IFNULL(DATE(ofr.valid_from),'9999-12-31') AND IFNULL(DATE(ofr.valid_to),'2000-01-01') 
          AND CURRENT_DATE('EST') BETWEEN IFNULL(DATE(price.valid_from),'9999-12-31') AND IFNULL(DATE(price.valid_to),'2000-01-01') 
          THEN "P - All Checks Passed" ELSE "" END
    # ||CASE WHEN price_RC = '6' THEN 'F - Markdown,' ELSE "" END 
        ,",") -- Split the items above up BY commas 
        ,"; \n") -- Format for multiple items above BY separating each with a semicolon AND a linebreak 
        AS pcs_reason, 
      CASE 
        WHEN promo.reason_code > 0 THEN "1 - Promo"
        WHEN price.reason_code <> 4 THEN "2 - Special"
        ELSE "3 - Regular"
        END AS price_ranking,
      CASE 
        WHEN CURRENT_DATE('EST') BETWEEN IFNULL(DATE(price.valid_from),'9999-12-31') AND IFNULL(DATE(price.valid_to),'2000-01-01') THEN "1 - Current"
        WHEN CURRENT_DATE('EST') < IFNULL(DATE(price.valid_to),'2000-01-01') THEN "2 - Future"
        ELSE "3 - Past or NULL"
        END AS is_current_price
    FROM `ld-ds-bi-analytics-prod.product_catalog.offers` ofr
    LEFT JOIN UNNEST(prices) AS price
    LEFT JOIN UNNEST(promotions) AS promo
    LEFT JOIN `ld-ds-bi-analytics-prod.product_catalog.products` pt USING (liam)
    GROUP BY ALL
    QUALIFY ROW_NUMBER() OVER(PARTITION BY vendor.store_id, liam ORDER BY is_current_price,price_ranking) = 1 -- Only show the most current customer-facing price record per liam/store
    ),

  assortment AS (
    SELECT
      ao.*,
      pcs_result,
      pcs_reason
    FROM ao
    LEFT JOIN pcs_offers ON (store_id,liam) = (ao.store_number,article_uom) -- show all rows from assortment output, but only show pcs offers with a store and liam that matches the assortment output
    ),
    
  -- inventory section -- 
  uom AS (
    SELECT DISTINCT 
      storeID,
      articleID,
      CONCAT(articleID,"_",UOM) AS inv_liam,
      conversion_factor,
    FROM `ld-ds-bi-analytics-prod.assortment.InventoryUOMs`
    QUALIFY ROW_NUMBER() OVER(PARTITION BY storeID, articleID, UOM ORDER BY insertTimestamp DESC) = 1 -- Only consider most recent record conversion_factor FOR that liam/store 
    ),
    
  inv AS (
    -- All stores except MFC 6885 location
    SELECT
      LTRIM(ARTICLE_NUM,'0') AS inv_article,
      inv_liam,
      LTRIM(SITE,'0') AS inv_site,
      CURRENT_STOCK,
      DISMM,
      conversion_factor,
      SAFE_MULTIPLY(IFNULL(CURRENT_STOCK,0),IFNULL(conversion_factor,0)) AS converted_units, --Inventory units for the liam in case different than for the article
      MARD_TIMESTAMP,
      DATE(PART_TIMESTAMP) AS inventory_run_date,
      CAST(NULL AS STRING)  AS scenario
    FROM `ld-ds-bi-analytics-prod.inventory.inventory`
    JOIN uom 
      ON LTRIM(ARTICLE_NUM,'0') = LTRIM(articleID,'0')
      AND LTRIM(SITE,'0') = LTRIM(storeID,'0')
    WHERE DATE(PART_TIMESTAMP) >= CURRENT_DATE("EST") - 60 -- Check 60 days worth OF DATA
      AND site <> '6885'
    QUALIFY ROW_NUMBER() OVER(PARTITION BY inv_liam, SITE ORDER BY MARD_TIMESTAMP DESC) = 1 -- Get the most recent inventory record of each liam/store
    
    UNION DISTINCT
    -- Match up items from MFC store 6885 with their inventory at store 7154
    SELECT
      LTRIM(ARTICLE_NUM,'0') AS inv_article,
      inv_liam,
      '6885' AS inv_site,
      CURRENT_STOCK,
      DISMM,
      conversion_factor,
      SAFE_MULTIPLY(IFNULL(CURRENT_STOCK,0),IFNULL(conversion_factor,0)) AS converted_units, --Inventory units for the liam in case different than for the article
      MARD_TIMESTAMP,
      DATE(PART_TIMESTAMP) AS inventory_run_date,
      CASE 
        WHEN site = '6885' AND current_stock > 0 THEN "1 - 6885 inventory" 
        WHEN site = '7154' AND current_stock > 0 THEN "2 - 7154 inventory"
        ELSE "3 - OOS"
        END AS scenario
    FROM `ld-ds-bi-analytics-prod.inventory.inventory`
    JOIN uom 
      ON LTRIM(ARTICLE_NUM,'0') = LTRIM(articleID,'0')
    WHERE DATE(PART_TIMESTAMP) >= CURRENT_DATE("EST") - 60 -- Check 60 days worth OF DATA
      AND site IN ('6885','7154') 
      AND uom.storeID = '6885'
    QUALIFY ROW_NUMBER() OVER(PARTITION BY inv_liam, SITE ORDER BY MARD_TIMESTAMP DESC) = 1 -- Get the most recent inventory record of each liam/store
      AND ROW_NUMBER() OVER(PARTITION BY inv_liam ORDER BY scenario ASC) = 1 -- Only show relevant store_scenario for MFC inventory
    ),
  
  pi AS (
    SELECT DISTINCT 
      LTRIM(matnr,'0') AS article,
      LTRIM(werks,'0') AS store,
      isAccuratePI = 1 AS is_PI
    FROM `ld-ds-bi-analytics-prod.assortment.sap_article_info` 
    )


SELECT
  assortment.*,
  pi.is_PI,
  i.MARD_TIMESTAMP AS most_recent_inventory_change_ts,
  i.CURRENT_STOCK AS most_recent_current_stock_value,
  i.conversion_factor AS most_recent_conversion_factor,
  i.converted_units AS most_recent_converted_units,
  CASE
    WHEN is_PI IS NULL THEN "Unknown" -- PI requirement is unknown
    WHEN is_PI IS FALSE THEN "In Stock" -- Item passes algo and does not require PI
    WHEN converted_units IS NULL THEN "Unknown" -- Stock level is unknown for the liam
    WHEN converted_units <= 0 THEN "Out of Stock"
    WHEN converted_units <= 3 THEN "Low Stock"
    WHEN converted_units > 3 THEN "In Stock"
    END AS most_recent_stock_badge,
FROM assortment
LEFT JOIN inv AS i
  ON LTRIM(assortment.store_number,'0') = i.inv_site
  AND assortment.article_uom = i.inv_liam
LEFT JOIN pi
  ON assortment.article = pi.article
  AND LTRIM(assortment.store_number,'0') = pi.store