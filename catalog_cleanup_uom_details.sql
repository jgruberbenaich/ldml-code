WITH prep AS(
  SELECT liam,
    name_en,
    name_fr,
    mch_3_desc_en AS mch_3,
    mch_2_desc_en AS mch_2,
    mch_1_desc_en AS mch_1,
    mch_0_desc_en AS mch_0,
    mch_0_cd,
    uom,
    attributes.items_per_package,
    attributes.item_size,
    attributes.item_size_uom,
    attributes.sold_by_uom,
    attributes.sold_by_unit,
    attributes.sold_by_incr,
    attributes.comparison_unit,
    attributes.comparison_uom,
    attributes.additional_comparison_unit,
    attributes.additional_comparison_uom,
    attributes.min_order_quantity,
    attributes.max_order_quantity,
    CASE 
      WHEN uom = "KG" AND attributes.sold_by_uom IN ("KG","G","LB") THEN "Priced & Sold by Weight"
      WHEN uom = "KG" AND attributes.sold_by_uom NOT IN ("KG","G","LB") THEN "Price by Weight, Sold by Each"
      WHEN uom <> "KG" THEN "Priced & Sold by Each"
      END AS selling_type,
    CASE WHEN UPPER(attributes.item_size_uom) NOT IN ("EA","ML","L","G","KG","LB") THEN TRUE -- item size uom should be from these options
      ELSE FALSE
      END AS check_item_size,
    CASE 
      WHEN UPPER(attributes.sold_by_uom) NOT IN ("EA","KG","G","LB") THEN TRUE -- sold by uom not found in PCS dropdown
      WHEN attributes.sold_by_unit <> attributes.sold_by_incr THEN TRUE -- sold by details don't match
      ELSE FALSE 
      END AS check_sold_by,
    CASE 
      WHEN UPPER(attributes.sold_by_uom) NOT IN ("KG","G","LB") AND mch_0_cd = "M10020106" AND attributes.max_order_quantity <> 3 THEN TRUE -- infant formula
      WHEN UPPER(attributes.sold_by_uom) NOT IN ("KG","G","LB") AND attributes.max_order_quantity NOT IN (24,25) THEN TRUE -- Sold By Weight item
      WHEN UPPER(attributes.sold_by_uom) IN ("KG","G","LB") AND attributes.max_order_quantity <> 999 THEN TRUE
      ELSE FALSE
      END AS check_max,
    CASE 
      WHEN attributes.comparison_uom NOT IN ('EA','KG','G','ML') THEN TRUE -- Not a valid comparison unit
      WHEN attributes.comparison_uom = attributes.additional_comparison_uom THEN TRUE -- Comparison unit is duplicated (i.e. should be per 100g and 1lb rather than per 100g written twice)
      ELSE FALSE
      END AS check_comparison
  FROM `ld-ds-bi-analytics-prod.product_catalog.products`
  JOIN `ld-pcx-bia.Merch_PIM.PCX_ACTIVE_ARTICLE_STORES` USING(article_number)
  JOIN `lt-dia-lake-prd-consume.product.article_curr` ON article_number = artcl_num
  WHERE status = "APPROVED"
    AND liam LIKE "2%")

SELECT *
FROM prep
WHERE check_item_size = TRUE
  OR check_sold_by = TRUE
  OR check_max = TRUE
  OR check_comparison = TRUE