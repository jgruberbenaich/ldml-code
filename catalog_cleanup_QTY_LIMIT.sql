WITH prep AS (
SELECT liam,
  name_en AS pcx_name_en,
  artcl_med_desc_en AS sap_desc_en,
  attributes.item_size,
  attributes.item_size_uom,
  attributes.estimated_typical_weight,
  attributes.min_order_quantity, 
  attributes.max_order_quantity, 
  uom, 
  attributes.sold_by_uom,
  mch_0_cd,
  mch_3_desc_en AS mch_3,
  mch_2_desc_en AS mch_2,
  mch_1_desc_en AS mch_1,
  mch_0_desc_en AS mch_0,
  CASE 
    WHEN mch_0_cd = "M10020106" AND attributes.max_order_quantity <> 3 THEN "INFANT FORMULA <> 3"
    WHEN NOT (uom = "KG" AND attributes.sold_by_uom IN ("G","KG","LB")) AND (attributes.min_order_quantity > 1 OR attributes.max_order_quantity > 25) THEN "CHANGE MIN/MAX 1/25"
    WHEN attributes.sold_by_uom IN ('KG') AND mch_3_desc_en NOT IN ('Meat','Seafood','Produce') THEN "CHANGE SOLD BY UOM TO G"
    WHEN attributes.sold_by_uom IN ('KG') AND mch_3_desc_en IN ('Meat','Seafood','Produce') THEN "CHANGE SOLD BY UOM TO EA"
    WHEN (uom = "KG" AND attributes.sold_by_uom IN ("G")) AND (attributes.min_order_quantity NOT IN (50,100) OR attributes.max_order_quantity <> 999) THEN "CHANGE MIN/MAX TO 100/999"
    WHEN attributes.sold_by_uom NOT IN ('EA','G') THEN 'CHANGE SOLD BY UOM TO EA'
    END AS scenario 
FROM `ld-ds-bi-analytics-prod.product_catalog.products`
JOIN `lt-dia-lake-prd-consume.product.article_curr` ON article_number = artcl_num
WHERE liam LIKE "2%"
  AND status = "APPROVED"
  AND NOT (liam IN ("20036155001_KG")) -- Exceptional cases not to be updated
)

SELECT *
FROM prep
WHERE scenario IS NOT NULL