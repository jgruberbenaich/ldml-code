-- Query to create product descriptions using the GS1 data
-- Use the Brand Owner Product Marketing Message as the top paragraph, and features and benefits (if any) unordered list items

SELECT gtin_cd, artcl_num,
brnd_own_prod_mkt_eng_msg,
CONCAT("<ul>",STRING_AGG(CONCAT("<li>",fb.feats_and_bnfts_eng,"</li>"),""),"</ul>") AS fb_en,
CONCAT(IFNULL(brnd_own_prod_mkt_eng_msg,""),IFNULL(CONCAT("<ul>",STRING_AGG(CONCAT("<li>",fb.feats_and_bnfts_eng,"</li>"),""),"</ul>"),"")) AS gs1_description_en,
brnd_own_prod_mkt_fr_msg,
CONCAT("<ul>",STRING_AGG(CONCAT("<li>",fb.feats_and_bnfts_fr,"</li>"),""),"</ul>") AS fb_fr,
CONCAT(IFNULL(brnd_own_prod_mkt_fr_msg,""),IFNULL(CONCAT("<ul>",STRING_AGG(CONCAT("<li>",fb.feats_and_bnfts_fr,"</li>"),""),"</ul>"),"")) AS gs1_description_fr,
FROM `lt-dia-lake-prd-consume.product.ecommerce_content_curr`
LEFT JOIN UNNEST(feats_and_bnfts) AS fb
WHERE artcl_num LIKE "2%"
GROUP BY ALL
HAVING STRING_AGG(fb.feats_and_bnfts_eng) IS NOT NULL
LIMIT 50;
 