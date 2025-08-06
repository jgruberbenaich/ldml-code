With base_table as (SELECT wff.*, split(wff.Correct_Articles,'_')[safe_ordinal(1)] as Article,
wff.Merchant as Banner,
wff.Flyer_Run_Name as Region,
wff.page as pg,
case  when Merchant ='Real Canadian Superstore' and Flyer_Run_Name ='ONT' then Concat(split(wff.Correct_Articles,'_')[safe_ordinal(1)],'RCSO')
      when Merchant ='Real Canadian Superstore' and Flyer_Run_Name ='WEST' then Concat(split(wff.Correct_Articles,'_')[safe_ordinal(1)],'RCSW')
      when Merchant ='Your Independent Grocer' and Flyer_Run_Name ='WEST' then Concat(split(wff.Correct_Articles,'_')[safe_ordinal(1)],'YIGW')
      when Merchant ='Your Independent Grocer' and Flyer_Run_Name ='ONT' then Concat(split(wff.Correct_Articles,'_')[safe_ordinal(1)],'YIGO')
      when Merchant ='Your Independent Grocer' and Flyer_Run_Name ='ATL' then Concat(split(wff.Correct_Articles,'_')[safe_ordinal(1)],'YIGA')
      when Merchant ='Zehrs' then Concat(split(wff.Correct_Articles,'_')[safe_ordinal(1)],'ZEHRS')
      when Merchant ='Loblaws' then Concat(split(wff.Correct_Articles,'_')[safe_ordinal(1)],'LOB')
      when Merchant ='Provigo' then Concat(split(wff.Correct_Articles,'_')[safe_ordinal(1)],'PRO')
      when Merchant ='Valu-Mart' then Concat(split(wff.Correct_Articles,'_')[safe_ordinal(1)],'VM')
      when Merchant ='Maxi' then Concat(split(wff.Correct_Articles,'_')[safe_ordinal(1)],'MAXI')
      when Merchant LIKE 'Fortino%' then Concat(split(wff.Correct_Articles,'_')[safe_ordinal(1)],'FORT')
      when Merchant ='No Frills' then Concat(split(wff.Correct_Articles,'_')[safe_ordinal(1)],'NF')
      when Merchant ='Atlantic Superstore' then Concat(split(wff.Correct_Articles,'_')[safe_ordinal(1)],'RASS')
      when Merchant ='Dominion' then Concat(split(wff.Correct_Articles,'_')[safe_ordinal(1)],'DOM')
      when Merchant ='Independent City Market' then Concat(split(wff.Correct_Articles,'_')[safe_ordinal(1)],'VM')
      when Merchant LIKE 'Wholesale Club%' then Concat(split(wff.Correct_Articles,'_')[safe_ordinal(1)],'RCWC')
      ELSE NULL END AS RPcheckindex,
 case  when Merchant ='Real Canadian Superstore' and Flyer_Run_Name ='ONT' then 'superstoreo'
      when Merchant ='Real Canadian Superstore' and Flyer_Run_Name ='WEST' then 'superstorew'
      when Merchant ='Your Independent Grocer' and Flyer_Run_Name ='WEST' then 'independentw'
      when Merchant ='Your Independent Grocer' and Flyer_Run_Name ='ONT' then 'independento'
      when Merchant ='Your Independent Grocer' and Flyer_Run_Name ='ATL' then 'independenta'
      when Merchant ='Zehrs' then 'zehrs'
      when Merchant ='Loblaws' then 'loblaw'
      when Merchant ='Provigo' then 'provigo'
      when Merchant ='Valu-Mart' then 'valumart'
      when Merchant ='Maxi' then 'maxi'
      when Merchant LIKE 'Fortino%' then 'fortinos'
      when Merchant ='No Frills' then 'nofrills'
      when Merchant ='Atlantic Superstore' then 'rass'
      when Merchant ='Dominion' then 'dominion'
      when Merchant ='Independent City Market' then 'independentcitymarket'
      when Merchant LIKE 'Wholesale Club%' then 'wholesaleclub'
      ELSE NULL END AS forcebanner,
      pcs.status as approval_status
  FROM `ld-pcx-bia.Merch_Flyer.Weekly Flipp Flyer`  wff
left join `ld-ds-bi-analytics-prod.product_catalog.products` pcs on wff.correct_articles = pcs.liam)
, RP_Check as (SELECT DISTINCT
LTRIM(MATNR, '0') as article_number,
  concat(LTRIM(MATNR, '0'),store_banner_code) as article_banner,
  da.mch_3_desc_english mch3_name,
  DISMM
  FROM `ld-ds-bi-analytics-prod.cerebro_reporting.sap_ecc_marc` M
  LEFT JOIN `ld-ds-bi-analytics-prod.bi_dw.pcx_stores` S
  ON LTRIM(M.WERKS, '0') = S.store_number
  INNER JOIN `ld-ds-bi-analytics-prod.assortment.stores_hybris`H
ON ltrim(H.id,'0') = S.store_number
  left join `ld-ds-bi-analytics-prod.bi_reporting.pcx_teradata_articles` da on da.article_number = LTRIM(MATNR, '0')
  WHERE DELETED_FLAG = FALSE
  AND concat(LTRIM(MATNR, '0'),store_banner_code) in (select distinct RPcheckindex from base_Table)
 AND DISMM in ('RE', 'ND', 'ZA')
  and store_banner_code IS NOT NULL
  AND not store_banner_code = 'Unknown'
  AND H.clickandcollect = true
  GROUP BY 1,2,3,4)
select bt.Banner, bt.Region,bt.pg,bt.correct_articles, forcebanner, rp.mch3_name,rp.DISMM,
CASE 
  WHEN mch3_name NOT IN ('Floral', 'Garden', 'Home & Entertainment') 
      AND DISMM in ('ND', 'ZA') 
    THEN "condition_1"
  WHEN mch3_name IN ('Meat','Seafood') 
      AND (pg LIKE "01%" OR pg LIKE "% 01 %" OR LOWER(pg) LIKE "%et01%" 
        OR LOWER(pg) LIKE "%flap 01%" OR LOWER(pg) LIKE "%flap 02%" 
        OR (LOWER(pg) LIKE "%flap1%" AND LOWER(pg) NOT LIKE "%online%") OR (LOWER(pg) LIKE "%flap2%" AND LOWER(pg) NOT LIKE "%online%")) 
      AND DISMM ='RE' 
    THEN 'condition_2'
  END AS filter_testing
from base_table as bt 
left join RP_Check rp on bt.RPcheckindex = rp.article_banner