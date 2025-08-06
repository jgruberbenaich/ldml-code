SELECT liam, sap_name, mch_3, mch_2, mch_1, mch_0, estimated_typical_weight AS old_avg_wt, median_wt AS suggested_avg_wt
FROM `ld-pcx-bia.Merch_PIM.avg_weight_check`
WHERE liam IN ('20798456_KG') -- Replace with list of liams being checked