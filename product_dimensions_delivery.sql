SELECT DISTINCT 
  liam, 
  mch_3,
  mch_2,
  mch_1,
  mch_0,
  mch_0_code,
  ah_4,
  ah_5,
  article_number,
  EN_1,
  upc,
  sap_name_en,
  brand_en,
  pcx_name_en,
  pcs_items_per_package,
  pcs_item_size,
  pcs_item_size_uom,
  relative_delivery_quantity,
  restricted_pickup_types,
  vol_qty,
  artcl_lgth,
  artcl_wdth,
  artcl_ht,
  gross_wgt_qty
  dim_uom_cd,
  total_stores,
  L52W_rtl_sales,
  sap_creationdate
FROM `ld-pcx-bia.Merch_PIM.PCX_PRODUCT_INFORMATION_DASHBOARD`
JOIN `lt-dia-lake-prd-consume.product.article_curr` ON article_number = artcl_num
LIMIT 10;