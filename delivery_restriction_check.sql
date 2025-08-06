SELECT artcl_num,
  artcl_med_desc_en AS sap_description,
  IFNULL(brand.name_en,brnd_desc_en) AS brand,
  mch_3_desc_en AS mch_3,
  mch_2_desc_en AS mch_2,
  mch_1_desc_en AS mch_1,
  mch_0_desc_en AS mch_0,
  mch_0_cd,
  ah_04_desc_en AS ah_04,
  ah_05_desc_en AS ah_05,
  gross_wgt_qty,
  artcl_ht,
  artcl_wdth,
  artcl_lgth,
  vol_qty,
  total_stores AS active_stores,
  liam AS pcs_liam,
  IFNULL(p.status,"PENDING / NOT FOUND") AS pcs_status,
  attributes.relative_delivery_quantity,
  REGEXP_CONTAINS(ARRAY_TO_STRING(restricted_pickup_types,","),"DELIVERY") AS delivery_restricted
FROM `lt-dia-lake-prd-consume.product.article_curr` a
JOIN `ld-pcx-bia.Merch_PIM.PCX_ACTIVE_ARTICLE_STORES` s ON a.artcl_num = s.article_number 
LEFT JOIN `ld-ds-bi-analytics-prod.product_catalog.products` p ON a.artcl_num = p.article_number
WHERE mch_0_cd IN (
  'M14300101', -- Fertilizers & Pestic
  'M14300102', -- Gardening Accesorie
  'M14300103', -- Live Plant Material
  'M14300104', -- Seeds & Bulbs
  'M14300105' -- Soils & Mulches
)
ORDER BY mch_0_cd, active_stores DESC