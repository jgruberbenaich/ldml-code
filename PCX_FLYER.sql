With week_year as (select Promo_Week,Promo_Year from `ld-pcx-bia.Merch_Flyer.PromoWeek` where 
date = current_date("EST")+1)

select distinct
case when dist_chnnl_nm_en ='Superstore' AND rgn_nm_en ='Sales Org Ontario' THEN 'superstoreo'
     when dist_chnnl_nm_en ='Atl Your Ind Grocer' AND rgn_nm_en ='Sales Org Atlantic' THEN 'independenta'
     WHEN dist_chnnl_nm_en ='Atlantic Superstore' THEN 'rass'
     WHEN dist_chnnl_nm_en ='Dominion' THEN 'dominion'
     WHEN dist_chnnl_nm_en ='Extra Foods' THEN 'extrafoods'
     WHEN dist_chnnl_nm_en ='Fortinos' THEN 'fortinos'
     WHEN dist_chnnl_nm_en ='Independents(Retail)' AND rgn_nm_en ='Sales Org Ontario' THEN 'independento'
     WHEN dist_chnnl_nm_en ='Independents(Retail)' AND rgn_nm_en ='Sales Org West' THEN 'independentw'
     WHEN dist_chnnl_nm_en ='Independents(Retail)' AND rgn_nm_en ='Sales Org Atlantic' THEN 'independenta'
     WHEN dist_chnnl_nm_en ='Independents(Retail)' AND rgn_nm_en ='Sales Org Quebec' THEN 'independenta'
     WHEN dist_chnnl_nm_en ='Loblaw' THEN 'loblaw'
     WHEN dist_chnnl_nm_en ='Maxi' THEN 'maxi'
     WHEN dist_chnnl_nm_en ='Nofrills' AND rgn_nm_en ='Sales Org West' THEN 'nofrillsw'
     WHEN dist_chnnl_nm_en ='Nofrills' AND rgn_nm_en ='Sales Org Atlantic' THEN 'nofrillsa'
     WHEN dist_chnnl_nm_en ='Nofrills' AND rgn_nm_en ='Sales Org Ontario' THEN 'nofrillso'
     WHEN dist_chnnl_nm_en ='Provigo' THEN 'provigo'
     WHEN dist_chnnl_nm_en ='Retail RCWC' THEN 'wholesaleclubw'
     when dist_chnnl_nm_en ='Superstore' AND rgn_nm_en ='Sales Org West' THEN 'superstorew'
     WHEN dist_chnnl_nm_en ='Valu-Mart' THEN 'valumart'
     WHEN dist_chnnl_nm_en ='Wholesale Club' AND rgn_nm_en ='Sales Org West' THEN 'wholesaleclubw'
     WHEN dist_chnnl_nm_en ='Wholesale Club' AND rgn_nm_en ='Sales Org Quebec' THEN 'wholesaleclubq'
     WHEN dist_chnnl_nm_en ='Wholesale Club' AND rgn_nm_en ='Sales Org National' THEN 'wholesaleclubw'
     WHEN dist_chnnl_nm_en ='Wholesale Club' AND rgn_nm_en ='Sales Org West' THEN 'wholesaleclubw'
     WHEN dist_chnnl_nm_en ='Wholesale Club' AND rgn_nm_en ='Sales Org Atlantic' THEN 'wholesalecluba'
     WHEN dist_chnnl_nm_en ='Wholesale Club' AND rgn_nm_en ='Sales Org Ontario' THEN 'wholesaleclubo'
     WHEN dist_chnnl_nm_en ='Your Ind Grocer' AND rgn_nm_en ='Sales Org Ontario' THEN 'independento'
     WHEN dist_chnnl_nm_en ='Your Ind Grocer' AND rgn_nm_en ='Sales Org West' THEN 'independentw'
     WHEN dist_chnnl_nm_en ='Zehrs' THEN 'zehrs'

     ELSE NULL
     END AS BANNER,
    concat(trim(a.artcl_num),'_',a.sl_uom_cd) AS Article_UOM
 from `lt-dia-abi-data-prod.TECHNICAL_TACTICAL.JDA_PROMO_FIN_RLUP` a
left join `lt-dia-lake-prd-consume.site_store.site_curr` b on (LOWER(a.DIST_CHNNL_NUM),a.PUR_ORG_NUM) =(LOWER(b.dist_chnnl_num),b.rgn_num)
join week_year c on concat(a.AD_YR_NUM,a.AD_WK_NUM) =concat(c.Promo_Year,c.Promo_Week)
where 1=1
AND a.reg_ut_prc_amt IS NOT NULL
and a.reg_ut_prc_amt > 0
and lang_use_cd ='E'
and Flyer_cell_num is not null
and dist_chnnl_nm_en not in ('Affiliate','Axep','Intermarche','RCLS')
ORDER BY 1,2