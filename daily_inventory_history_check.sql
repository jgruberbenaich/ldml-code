WITH

zzz AS (
-- update the values below for the details you want to check
  SELECT
    '1077' AS store, -- store number with or without leading zeros
    '21645037_EA' AS liam,
    '2025-06-01' AS timeframe_start, -- Beginning of the timeframe you want to see in the results
    '2025-06-30' AS timeframe_end -- End of the timeframe you want to see in the results
  ),

dt AS (
  SELECT DISTINCT cal_date
  FROM `ld-pcx-bia.dim.dates`
  CROSS JOIN zzz
  WHERE cal_date BETWEEN DATE(zzz.timeframe_start) AND DATE(zzz.timeframe_end)
  ORDER BY 1 DESC
  ),

pi AS (
  SELECT DISTINCT 
    LTRIM(matnr,'0') AS articleID,
    LTRIM(werks,'0') AS storeID,
    isAccuratePI
  FROM `ld-ds-bi-analytics-prod.assortment.sap_article_info`
  CROSS JOIN zzz
  WHERE 1=1
    AND LTRIM(matnr,'0') = SPLIT(zzz.liam,"_")[SAFE_ORDINAL(1)]
    AND LTRIM(werks,'0') = LTRIM(zzz.store,'0')
  ),

uom AS (
  SELECT
    storeID,
    articleID,
    CONCAT(articleID,"_",UOM) AS inv_liam,
    conversion_factor,
    pi.isAccuratePI
  FROM `ld-ds-bi-analytics-prod.assortment.InventoryUOMs`
  JOIN pi USING(articleID, storeID) -- only check items with are on PI
  CROSS JOIN zzz
  WHERE 1=1
    AND LTRIM(articleID,'0') = SPLIT(zzz.liam,"_")[SAFE_ORDINAL(1)]
    AND LTRIM(storeID,'0') = LTRIM(zzz.store,'0')
  QUALIFY ROW_NUMBER() OVER(PARTITION BY storeID, articleID, UOM ORDER BY insertTimestamp DESC) = 1 -- Only consider most recent record of conversion_factor for that liam/store
  ),

inv AS (
  SELECT
    LTRIM(ARTICLE_NUM,'0') AS inv_article,
    inv_liam,
    LTRIM(SITE,'0') AS inv_site,
    IFNULL(uom.isAccuratePI = 1,FALSE) AS accurate_PI,
    CURRENT_STOCK,
    DISMM,
    conversion_factor,
    SAFE_MULTIPLY(IFNULL(CURRENT_STOCK,0),IFNULL(conversion_factor,0)) AS converted_units,
    MARD_TIMESTAMP,
    PART_TIMESTAMP,
    DATE(PART_TIMESTAMP) AS inventory_run_date
  FROM `ld-ds-bi-analytics-prod.inventory.inventory`
  JOIN uom ON LTRIM(ARTICLE_NUM,'0') = LTRIM(articleID,'0')
    AND LTRIM(SITE,'0') = LTRIM(storeID,'0') -- only check items which have valid uom
  CROSS JOIN zzz
  WHERE 1=1
    AND DATE(PART_TIMESTAMP) >= DATE_SUB(DATE(zzz.timeframe_start), INTERVAL 365 DAY)-- Check 365 days before earliest day in dt CTE
    AND DATE(PART_TIMESTAMP) <= DATE(zzz.timeframe_end)
    AND LTRIM(ARTICLE_NUM,'0') = SPLIT(zzz.liam,"_")[SAFE_ORDINAL(1)]
    AND LTRIM(SITE,'0') = LTRIM(zzz.store,'0')
  QUALIFY ROW_NUMBER() OVER(PARTITION BY ARTICLE_NUM, SITE, inventory_run_date ORDER BY MARD_TIMESTAMP DESC, PART_TIMESTAMP DESC) = 1 -- Get the last daily inventory record per day for each article/store
    )

SELECT *
FROM dt
-- combination of the CROSS JOIN, WHERE, AND QUALIFY statements show the latest record (by mard_timestamp and part_timestamp) used on the cal_date
CROSS JOIN inv -- match every date in the timeframe to every record in the inv CTE
WHERE cal_date > DATE(MARD_TIMESTAMP) -- real_date is on or after the date of the inventory table updating
QUALIFY ROW_NUMBER() OVER(PARTITION BY inv_liam, inv_site, cal_date ORDER BY MARD_TIMESTAMP DESC) = 1 -- most recent inventory update record that is earlier than the real_date
ORDER BY inv_liam, inv_site, cal_date DESC