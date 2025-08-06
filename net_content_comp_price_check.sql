SELECT liam,
  selling_type,
  attributes.sold_by_uom,
  attributes.items_per_package,
  attributes.item_size,
  attributes.item_size_uom,
  attributes.items_per_package * attributes.comparison_multiplier * attributes.comparison_unit AS compsize,
  attributes.comparison_multiplier,
  attributes.comparison_unit,
  attributes.comparison_uom,
  attributes.items_per_package * attributes.additional_comparison_multiplier * attributes.additional_comparison_unit AS addtl_compsize,
  attributes.net_content,
  attributes.net_content_uom,
  total_stores
FROM `ld-ds-bi-analytics-prod.product_catalog.products`
JOIN `ld-pcx-bia.Merch_PIM.PCX_ACTIVE_ARTICLE_STORES` USING(article_number)
WHERE status = 'APPROVED'
  AND liam LIKE "2%"
  AND (SAFE_MULTIPLY(attributes.items_per_package,attributes.item_size) <> attributes.net_content
    OR UPPER(attributes.comparison_uom) <> UPPER(attributes.net_content_uom))
ORDER BY total_stores DESC