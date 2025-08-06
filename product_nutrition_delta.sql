with
nutrients as (
SELECT concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("productSize" as nutrientName, concat(pk_sz,' ',pk_sz_uom) as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where pk_sz is not null and pk_sz_uom is not null and serv_sz != "0" and serv_sz_uom in ('g','ml')  and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT  concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("servingSizeEN" as nutrientName, concat(serv_sz,' ',serv_sz_uom) as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where serv_sz is not null and serv_sz_uom is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT  concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("servingSizeFR" as nutrientName, serv_sz_fr as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where serv_sz_fr is not null and serv_sz_uom is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT  concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("houseHoldServingSize" as nutrientName, concat(hse_hld_sz,' ',hse_hld_uom) as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where hse_hld_sz is not null and hse_hld_uom is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("calories" as nutrientName, cal_qty as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where cal_qty is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT  concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("totalFat" as nutrientName, total_fat_wgt_g_qty as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where total_fat_wgt_g_qty is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT  concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("totalFat-DV" as nutrientName, total_fat_pct as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where total_fat_pct is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT  concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("saturatedFat" as nutrientName, satur_fat_wgt_g_qty as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where satur_fat_wgt_g_qty is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT  concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("saturFat-DV" as nutrientName, satur_fat_pct as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where satur_fat_pct is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("transFat" as nutrientName, trans_fat_wgt_g_qty as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where trans_fat_wgt_g_qty is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT  concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("transFat-DV" as nutrientName, total_trans_fat_pct as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where total_trans_fat_pct is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT  concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("saturatedTransFat" as nutrientName, combnd_satur_trans_fat_qty as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where combnd_satur_trans_fat_qty is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("saturatedTransFat-DV" as nutrientName, combnd_satur_trans_fat_pct as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where combnd_satur_trans_fat_pct is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT  concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("totalCarbohydrate" as nutrientName, carb_wgt_g_qty as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where carb_wgt_g_qty is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT  concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("totalCarbohydrate-DV" as nutrientName, carb_pct as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where carb_pct is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("dietaryFiber" as nutrientName, fiber_wgt_g_qty as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where fiber_wgt_g_qty is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT  concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("dietaryFiber-DV" as nutrientName, fiber_pct as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where fiber_pct is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT  concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("sugar" as nutrientName, sugar_wgt_g_qty as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where sugar_wgt_g_qty is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("sugar-DV" as nutrientName, sugar_pct as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where sugar_pct is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("protein" as nutrientName, protn_wgt_g_qty as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where protn_wgt_g_qty is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT  concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("protein-DV" as nutrientName, protn_pct as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where protn_pct is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT  concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("cholesterol" as nutrientName, chol_wgt_mg_qty as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where chol_wgt_mg_qty is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("cholesterol-DV" as nutrientName, chol_pct as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where chol_pct is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("sodium" as nutrientName, sod_wgt_mg_qty as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where sod_wgt_mg_qty is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT  concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("sodium-DV" as nutrientName, sod_pct as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where sod_pct is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT  concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("vitaminA" as nutrientName, vit_a_qty as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where vit_a_qty is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("vitaminA-DV" as nutrientName, vit_a_pct as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where vit_a_pct is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("vitaminC" as nutrientName, vit_c_qty as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where vit_c_qty is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT  concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("vitaminC-DV" as nutrientName, vit_c_pct as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where vit_c_pct is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT  concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("potassium" as nutrientName, potassm_qty as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where potassm_qty is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("potassium-DV" as nutrientName, potassm_pct as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where potassm_pct is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("calcium" as nutrientName, calcium_qty as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where calcium_qty is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT  concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("calcium-DV" as nutrientName, calcium_pct as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where calcium_pct is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT  concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("iron" as nutrientName, iron_qty as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where iron_qty is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("iron-DV" as nutrientName, iron_pct as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where iron_pct is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("manganese" as nutrientName, mangnes_qty as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where mangnes_qty is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT  concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("manganese-DV" as nutrientName, mangnes_pct as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where mangnes_pct is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT  concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("molybdenum" as nutrientName, molybdnum_qty as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where molybdnum_qty is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("molybdenum-DV" as nutrientName, molybdnum_pct as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where molybdnum_pct is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("monounsaturatedFat" as nutrientName, monounsatur_fat_qty as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where monounsatur_fat_qty is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT  concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("monounsaturatedFat-DV" as nutrientName, monounsatur_fat_pct as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where monounsatur_fat_pct is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT  concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("niacin" as nutrientName, niacin_qty as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where niacin_qty is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("niacin-DV" as nutrientName, niacin_pct as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where niacin_pct is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("omega3" as nutrientName, omega3_qty as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where omega3_qty is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT  concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("omega3-DV" as nutrientName, omega3_pct as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where omega3_pct is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT  concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("otherCarbohydrates" as nutrientName, oth_carb_qty as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where oth_carb_qty is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("otherCarbohydrates-DV" as nutrientName, oth_carb_pct as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where oth_carb_pct is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT  concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("pantothenate" as nutrientName, pantohent_qty as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where pantohent_qty is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("pantothenate-DV" as nutrientName, pantohent_pct as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where pantohent_pct is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("phosphorous" as nutrientName, phosphrs_qty as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where phosphrs_qty is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT  concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("phosphorous-DV" as nutrientName, phosphrs_pct as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where phosphrs_pct is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT  concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("polyunsaturatedFat" as nutrientName, polyunsatur_fat_qty as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where polyunsatur_fat_qty is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("polyunsaturatedFat-DV" as nutrientName, polyunsatur_fat_pct as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where polyunsatur_fat_pct is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("riboflavin" as nutrientName, riboflavn_qty as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where riboflavn_qty is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT  concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("riboflavin-DV" as nutrientName, riboflavn_pct as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where riboflavn_pct is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT  concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("selenium" as nutrientName, selenm_qty as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where selenm_qty is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("selenium-DV" as nutrientName, selenm_pct as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where selenm_pct is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT  concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("sugarAlcohols" as nutrientName, sugar_alcohl_qty as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where sugar_alcohl_qty is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("sugarAlcohols-DV" as nutrientName, sugar_alcohl_pct as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where sugar_alcohl_pct is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("thiamine" as nutrientName, thiamin_qty as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where thiamin_qty is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT  concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("thiamine-DV" as nutrientName, thiamin_pct as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where thiamin_pct is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT  concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("vitaminB12" as nutrientName, vit_b12_qty as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where vit_b12_qty is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("vitaminB12-DV" as nutrientName, vit_b12_pct as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where vit_b12_pct is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("vitaminB6" as nutrientName, vit_b6_qty as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where vit_b6_qty is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT  concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("vitaminB6-DV" as nutrientName, vit_b6_pct as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where vit_b6_pct is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT  concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("vitaminD" as nutrientName, vit_d_qty as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where vit_d_qty is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("vitaminD-DV" as nutrientName, vit_d_pct as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where vit_d_pct is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT  concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("vitaminE" as nutrientName, vit_e_qty as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where vit_e_qty is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("vitaminE-DV" as nutrientName, vit_e_pct as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where vit_e_pct is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("vitaminK" as nutrientName, vit_k_qty as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where vit_k_qty is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT  concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("vitaminK-DV" as nutrientName, vit_k_pct as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where vit_k_pct is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT  concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("zinc" as nutrientName, zinc_qty as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where zinc_qty is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("zinc-DV" as nutrientName, zinc_pct as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where zinc_pct is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("biotin" as nutrientName, biotin_qty as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where biotin_qty is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT  concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("biotin-DV" as nutrientName, biotin_pct as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where biotin_pct is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT  concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("magnesium" as nutrientName, magnesm_qty as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where magnesm_qty is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("magnesium-DV" as nutrientName, magnesm_pct as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where magnesm_pct is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT  concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("iodine" as nutrientName, iodine_qty as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where iodine_qty is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("iodine-DV" as nutrientName, iodine_pct as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where iodine_pct is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("folicAcid" as nutrientName, folate_qty as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where folate_qty is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT  concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("folicAcid-DV" as nutrientName, folate_pct as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where folate_pct is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT  concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("dha" as nutrientName, dha_qty as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where dha_qty is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("dha-DV" as nutrientName, dha_pct as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where dha_pct is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("copper" as nutrientName, copper_qty as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where copper_qty is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT  concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("copper-DV" as nutrientName,copper_pct as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where copper_pct is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT  concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("chromium" as nutrientName, chromium_qty as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where chromium_qty is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("chromium-DV" as nutrientName, chromium_pct as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where chromium_pct is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("chloride" as nutrientName, chloride_qty as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where chloride_qty is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT  concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("chloride-DV" as nutrientName, chloride_pct as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where chloride_pct is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT  concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("caloriesFromFat" as nutrientName, cal_from_fat_qty as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where cal_from_fat_qty is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT concat(artcl_num,"_",sl_uom_cd) as productCode, src,
struct ("caloriesFromFat-DV" as nutrientName, calories_from_fat_pct as value) as nutrients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where calories_from_fat_pct is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'
),
ingredients as (
SELECT concat(artcl_num,"_",sl_uom_cd) as productCode, src, struct("ingredientsEN" as ingredientName, ingredient_dclrtn_en as value) as ingredients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where ingredient_dclrtn_en is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT concat(artcl_num,"_",sl_uom_cd) as productCode, src, struct("ingredientsFR" as ingredientName, ingredient_dclrtn_fr as value) as ingredients_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where ingredient_dclrtn_fr is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465' and rec_cre_tms >= '1990-06-13T10:38:47.046465'
)
,
descriptions as (
SELECT concat(artcl_num,"_",sl_uom_cd) as productCode, src, struct("prodDescriptionEN" as productDescName, artcl_med_desc_en as value) as descriptions_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where artcl_med_desc_en is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'

UNION ALL
SELECT concat(artcl_num,"_",sl_uom_cd) as productCode, src, struct("prodDescriptionFR" as productDescName, artcl_med_desc_fr as value) as descriptions_struct from `lt-dia-lake-prd-consume.product.product_nutrition_curr` 
where artcl_med_desc_fr is not null and serv_sz != "0" and serv_sz_uom in ('g','ml') and rec_cre_tms >= '1990-06-13T10:38:47.046465'
)
,
nutrients_array as (
select productCode
,src
, ARRAY_AGG(nutrients_struct) as nutrientsByRecipeType
from nutrients
group by productCode, src
)
,
ingredients_array as (
select productCode
,src
, ARRAY_AGG(ingredients_struct) as ingredientsByRecipeType
from ingredients
group by productCode, src
)
,
descriptions_array as (
select productCode
,src
, ARRAY_AGG(descriptions_struct) as productDescByRecipeType
from descriptions
group by productCode, src
)

select Coalesce(nutrients_array.productCode, ingredients_array.productCode, descriptions_array.productCode) as productCode,
 [struct(nutrientsByRecipeType,  ingredientsByRecipeType, productDescByRecipeType)] as productNutrientValueList
from nutrients_array
full outer join ingredients_array
on nutrients_array.productCode = ingredients_array.productCode
and nutrients_array.src = ingredients_array.src
full outer join descriptions_array
on nutrients_array.productCode = descriptions_array.productCode
and nutrients_array.src = descriptions_array.src