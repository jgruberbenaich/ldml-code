SELECT rolodex_name,
  "2025 Q1" AS scorecard_name, -- Update to relevant timeframe
  COUNT(DISTINCT article_uom) AS items,
  ROUND(AVG(enrichment_score),1) AS score,
  r.category AS supplier_type
FROM `ld-pcx-bia.Merch_PIM.2025Q1_SUPPLIER_SCORECARD_ITEMS` -- Update to table for relevant timeframe
LEFT JOIN `ld-pcx-bia.Merch_PIM.SUPPLIER_ROLODEX` r USING(rolodex_name)
GROUP BY ALL
ORDER BY 1