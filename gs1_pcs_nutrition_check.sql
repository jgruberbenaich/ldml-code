WITH
x AS (
  SELECT * FROM UNNEST([
    --Paste list of UPCs below this line
    '70734000034','70734538179'
    -- Paste List of UPCs above this line
  ]) AS gtin
),

g AS (
  SELECT gtin, 
    servingsizeenglish,
    servingsizefrench,
    calories,
    ingredientsenglish,
    ingredientsfrench
  FROM `lt-dia-lake-prd-raw.thirdparty_gs1.gs1_nutritional_content_curr_v`
  QUALIFY ROW_NUMBER() OVER(PARTITION BY gtin ORDER BY snapshot_time DESC, rec_cre_tms DESC, ncs_systemversion DESC) = 1
),

p AS (
  SELECT liam, 
    STRING_AGG(DISTINCT nr.ingredients.en) AS pcs_ing_en,
    STRING_AGG(DISTINCT nr.ingredients.fr) AS pcs_ing_fr,
    STRING_AGG(DISTINCT CONCAT(n.key, " ", n.value), ";\n") AS pcs_nft
  FROM `ld-ds-bi-analytics-prod.product_catalog.products`
    LEFT JOIN UNNEST(nutrition.recipes) AS nr
    LEFT JOIN UNNEST(nr.nutrients) AS n
  WHERE status = "APPROVED"
    AND liam LIKE "2%"
  GROUP BY ALL
)

SELECT x.gtin,
  servingsizeenglish AS gs1_servingsize_en,
  servingsizefrench AS gs1_servingsize_fr,
  calories AS gs1_calories,
  ingredientsenglish AS gs1_ingr_en,
  ingredientsfrench AS gs1_ingr_fr,
  n.artcl_num AS crbro_art,
  n.sl_uom_cd AS crbro_uom,
  n.serv_sz AS crbro_servingsize_en,
  n.serv_sz_fr AS crbro_servingsize_fr,
  n.cal_qty AS crbro_calories,
  n.ingredient_dclrtn_en AS crbro_ingr_en,
  n.ingredient_dclrtn_fr AS crbro_ingr_fr,
  p.liam,
  p.pcs_ing_en,
  p.pcs_ing_fr,
  p.pcs_nft
FROM x
LEFT JOIN g ON LTRIM(x.gtin,'0') = LTRIM(g.gtin,'0')
LEFT JOIN `lt-dia-lake-prd-consume.product.product_nutrition_curr` n ON LTRIM(x.gtin,'0') = LTRIM(n.gtin_cd,'0')
LEFT JOIN p ON CONCAT(n.artcl_num,"_",n.sl_uom_cd) = p.liam
