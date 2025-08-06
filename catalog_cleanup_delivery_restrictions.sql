WITH prep AS (
SELECT DISTINCT
  artcl_med_desc_en AS sap_name,
  mch_3_desc_en AS mch_3,
  mch_2_desc_en AS mch_2,
  mch_1_desc_en AS mch_1,
  mch_0_desc_en AS mch_0,
  mch_0_cd,
  ah_04_cd,
  ah_04_desc_en,
  ah_05_cd,
  ah_05_desc_en,
  total_stores AS active_stores,
  liam,
  p.article_number,
  gross_wgt_qty,
  artcl_ht,
  artcl_wdth,
  artcl_lgth,
  vol_qty,
  CONCAT('=HYPERLINK(CONCAT("https://clickncollect.s3.amazonaws.com/products/"',artcl_num,'/b1/en/front/',artcl_num,'_front_a05.png),',artcl_num,')') AS image_url,
  ARRAY_TO_STRING(p.restricted_pickup_types, ",") AS old_restrictions,
  CASE
    WHEN mch_1_cd IN ("M092602", "M092603") 
      AND IFNULL(ARRAY_TO_STRING(p.restricted_pickup_types, ","),"") NOT LIKE "%DELIVERY%" -- Delivery not restricted
      THEN "RESTRICT - Beer/Wine"
    
    WHEN (ah_05_cd IN ("257763","257726","257734","257727","257728","257733","235747","235748","257740","257785","257786","257783","257784","257781","257741","257745","235759","235757","235758","257753","239300","235665","257850","235658","235660","235659","235661","235662","235663","235664","257204","257757","257756","233974") -- AH5s that should be deliverable
      OR p.article_number IN ('20991197','20035239','20185743','21297546','21364357','20597414','21046667','20177633','20694521','21046695','21046673','20156353','21364351','20004856','20689707','20099364','20035718','20589438','20689706','21364161','20107967','20136987','20548123','21386973','20683669','20973145','21314614','21000395','21401604','21364510','21331839','21467645','20786390','20694349','20597728','21335741','21124535','20972246','21383068','21000390','21386977','21331834','20589432','21395193','20973191','21436559','20695646','20608393','21369161','20589431','20694342','21000396','21028427','20597413','20596412','20786789','20589180','21175016','21436551','21103601','21401199','21532353','20596985','21364346','21369902','21297537','20596984','21532355')) 
      AND ARRAY_TO_STRING(p.restricted_pickup_types, ",") LIKE "%DELIVERY%" -- Delivery restricted
      THEN 'RESTRICT - Hot HMR articles in cold AHs'

    WHEN ah_05_cd IN ("235696","257766","257683","257768","257780","257777","257778","257202","257716","235649","257688","257690","257915","235643","235644","257691","257689","257879","235703","257671","235651","235650","257831","257782","235654","235656","257208","235657","257205","257680","257681") -- AH5s that should be restricted
      AND p.article_number NOT IN ('20991197','20035239','20185743','21297546','21364357','20597414','21046667','20177633','20694521','21046695','21046673','20156353','21364351','20004856','20689707','20099364','20035718','20589438','20689706','21364161','20107967','20136987','20548123','21386973','20683669','20973145','21314614','21000395','21401604','21364510','21331839','21467645','20786390','20694349','20597728','21335741','21124535','20972246','21383068','21000390','21386977','21331834','20589432','21395193','20973191','21436559','20695646','20608393','21369161','20589431','20694342','21000396','21028427','20597413','20596412','20786789','20589180','21175016','21436551','21103601','21401199','21532353','20596985','21364346','21369902','21297537','20596984','21532355')
      AND IFNULL(ARRAY_TO_STRING(p.restricted_pickup_types, ","),"") NOT LIKE "%DELIVERY%" -- Delivery not restricted
      THEN 'DO NOT RESTRICT - Cold HMR articles in hot AHs'

    WHEN mch_1_cd = "M074202"
      AND IFNULL(ARRAY_TO_STRING(p.restricted_pickup_types, ","),"") NOT LIKE "%DELIVERY%" -- Delivery not restricted
      THEN "RESTRICT - Gaming"
    
    WHEN mch_0_cd IN ("M14300103","M14300105")
      AND IFNULL(ARRAY_TO_STRING(p.restricted_pickup_types, ","),"") NOT LIKE "%DELIVERY%" -- Delivery not restricted
      THEN "RESTRICT - Garden Life Plant Material/Soils & Mulches"

    WHEN mch_0_cd = "M11320204"
      AND IFNULL(ARRAY_TO_STRING(p.restricted_pickup_types, ","),"") NOT LIKE "%DELIVERY%" -- Delivery not restricted
      THEN "RESTRICT - Live Seafood"

    WHEN ah_05_cd IN ('236081','236082','236083','236084')
      AND IFNULL(ARRAY_TO_STRING(p.restricted_pickup_types, ","),"") NOT LIKE "%DELIVERY%" -- Delivery not restricted
      THEN "RESTRICT - Home BBQ/Patio Items"


    WHEN ARRAY_TO_STRING(p.restricted_pickup_types, ",") LIKE "%DELIVERY%"
      AND mch_0_cd <> "M11320204" -- Seafood
      AND mch_1_cd NOT IN ("M092602", "M092603") -- Beer & Wine
      AND mch_1_cd <> "M074202" -- Gaming
      AND ah_05_cd NOT IN ('236081','236082','236083','236084') -- Home BBQ/Patio Items
      THEN "Unknown - Delivery Restricted"

  END AS cleanup_scenario
FROM `ld-ds-bi-analytics-prod.product_catalog.products` p
  JOIN `lt-dia-lake-prd-consume.product.article_curr` a ON p.article_number = a.artcl_num
  LEFT JOIN `ld-pcx-bia.Merch_PIM.PCX_ACTIVE_ARTICLE_STORES` c ON p.article_number = c.article_number
WHERE 1=1
  AND status = "APPROVED"
  AND liam LIKE "2%"
  AND liam NOT IN ("21552190_EA","20157310_KG","20035376_KG","20000953_KG") -- Excluded items
ORDER BY mch_0_desc_en, ah_04_desc_en, ah_05_desc_en)

SELECT *
FROM prep
WHERE cleanup_scenario IS NOT NULL
