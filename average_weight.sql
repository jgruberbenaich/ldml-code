WITH dates AS (
----change the start and end date to recent 2 months
SELECT CURRENT_DATE()- INTERVAL 12 WEEK AS start_date,
    CURRENT_DATE() AS end_date
)

SELECT 
    SPLIT(I.element.ArticleNum, '_')[OFFSET(0)] AS Article, 
    ROUND(SUM(I.element.salequantity),0) AS TotalSaleQuantity,
    ROUND(SUM(I.element.saleweightquantity),3) AS TotalSaleWeight,
    ROUND(SUM(I.element.saleweightquantity)/SUM(I.element.salequantity),3) AS avg_weight
  FROM `ld-ds-bi-analytics-prod.tlogs.tlogs`
    ,UNNEST(items.list) I
    ,dates D
  WHERE DATE(bigqueryPartition) > CURRENT_DATE() - INTERVAL 1 MONTH
    AND DATE(TIMESTAMP_TRUNC(header.transactionstartdatetime, DAY)) BETWEEN start_date AND end_date
-- change the following line to be a list of article numbers you are looking for 
    AND SPLIT(I.element.ArticleNum, '_')[OFFSET(0)]  in ('20797507')
    AND SPLIT(I.element.ArticleNum, '_')[OFFSET(1)]  = "KG"
  GROUP BY ALL