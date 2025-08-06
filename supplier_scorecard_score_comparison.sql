SELECT rolodex_name, 
  ROUND(AVG(q2.enrichment_score),2) AS q2_score, 
  COUNT(DISTINCT q2.article_uom) AS q2_products,
  ROUND(AVG(q3.enrichment_score),2) AS q3_score, 
  COUNT(DISTINCT q3.article_uom) AS q3_products,
  ROUND(SAFE_SUBTRACT(ROUND(AVG(q3.enrichment_score),2),ROUND(AVG(q2.enrichment_score),2)),1) AS q3_improvement
FROM `ld-pcx-bia.Merch_PIM.2024Q3_SUPPLIER_SCORECARD_ARTICLES` q3
JOIN `ld-pcx-bia.Merch_PIM.Q2_SUPPLIER_SCORECARDS_V2` q2 USING(rolodex_name)
GROUP BY ALL
ORDER BY UPPER(rolodex_name)