WITH

pi AS (
  SELECT LTRIM(matnr,'0') AS article,
    LTRIM(WERKS,'0') AS store,
    isAccuratePI AS is_PI -- '1' means this product at this store uses PI for OOS badging
  FROM `ld-ds-bi-analytics-prod.assortment.sap_article_info`
  )

SELECT LTRIM(ARTICLE_NUM,'0') AS article,
  SITE AS store_number,
  CURRENT_STOCK,
  DISMM,
  is_PI,
  CASE -- Unclear how other QTY fields are factored into stock badging
    WHEN is_PI <> 1 THEN "In Stock" -- Item is not on PI, assume it is in stock if it's offered
    WHEN CURRENT_STOCK <= 0 THEN "Out of Stock" 
    WHEN CURRENT_STOCK <= 3 THEN "Low Stock" 
    WHEN CURRENT_STOCK > 3 THEN "In Stock"
    END AS stock_badge,
    MARD_TIMESTAMP
FROM `ld-ds-bi-analytics-prod.inventory.inventory`
LEFT JOIN pi ON LTRIM(ARTICLE_NUM,'0') = pi.article AND LTRIM(SITE,'0') = pi.store
WHERE PART_TIMESTAMP >= DATE_SUB(CURRENT_TIMESTAMP,INTERVAL 1 DAY)
  AND SITE = "1077" -- Example store RCSO DonMills
QUALIFY ROW_NUMBER() OVER(PARTITION BY ARTICLE_NUM,SITE ORDER BY MARD_TIMESTAMP DESC) = 1 -- Only consider most recent record for this article/store