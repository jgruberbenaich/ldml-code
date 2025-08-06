SELECT DISTINCT * EXCEPT(rolodex_name)
FROM `ld-pcx-bia.Merch_PIM.supplier_scorecard_v`
WHERE rolodex_name = 'Highliner Foods' -- replace with rolodex_name used in supplier rolodex
ORDER BY sort_order