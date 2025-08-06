WITH

wkyr AS (
  SELECT promo_wk AS promo_week, promo_yr AS promo_year, CONCAT(promo_yr,promo_wk) AS promo_yr_wk
  FROM `ld-pcx-bia.dim.dates` 
  WHERE cal_date = CURRENT_DATE("EST")+1
),

f AS (
  SELECT DISTINCT
    CONCAT(TRIM(artcl_num),'_',sl_uom_cd) AS Article_UOM,
    DIST_CHNNL_NUM,
    PUR_ORG_NUM
  FROM `lt-dia-abi-data-prod.TECHNICAL_TACTICAL.JDA_PROMO_FIN_RLUP`
  JOIN wkyr ON promo_year = ad_yr_num AND promo_week = AD_WK_NUM
  WHERE 1=1
    AND reg_ut_prc_amt IS NOT NULL
    AND reg_ut_prc_amt > 0
    AND Flyer_cell_num IS NOT NULL
    AND dist_chnnl_num NOT IN ('19','21','22','23','24') -- Exclude stores with distribution channels for RCLS(19), Affiliate(21), Independents(Retail)(22),Axep(23), and Intermarche(24)
),

s AS ( -- List of all combinations of region/distribution channel/banner with at least one active PCX store in a relevant banner/distribution channel
  SELECT DISTINCT
    rgn_num,
    rgn_nm_en,
    dist_chnnl_num,
    dist_chnnl_nm_en,
    banner,
    banner_name
  FROM `lt-dia-lake-prd-consume.site_store.site_curr`
  JOIN `ld-pcx-bia.dim.stores_flip` ON LTRIM(site_num,'0') = LTRIM(hub_store_number,'0')
  WHERE 1=1 
    AND banner NOT IN ('EF','JF','NN','RAPID','RCLS','TT') -- Exclude Extra Foods, Joe Fresh, No Name, Rapid, RCLS, and T&T stores
    AND open_date < CURRENT_DATE('EST')
    AND og_close_date > CURRENT_DATE('EST')
)

SELECT DISTINCT 
  f.Article_UOM,
  f.pur_org_num AS region_number,
  s.rgn_nm_en AS region_name,
  f.dist_chnnl_num AS distribution_number, 
  s.dist_chnnl_nm_en AS distribution_name,
  s.banner,
  CASE 
    WHEN f.dist_chnnl_num LIKE "12" THEN "valumart" -- Some sources consider valumart part of YIG so use the distribution channel num to identify valumart
    WHEN banner LIKE "DOM" THEN "dominion"
    WHEN banner LIKE "FORT" THEN "fortinos"
    WHEN banner LIKE "EF" THEN "extrafoods"
    WHEN banner LIKE "LOB%" THEN "loblaw"
    WHEN banner LIKE "MAXI" THEN "maxi"
    WHEN banner LIKE "NF" AND rgn_nm_en LIKE "%Atlantic" THEN "nofrillsa"
    WHEN banner LIKE "NF" AND rgn_nm_en LIKE "%Ontario" THEN "nofrillso"
    WHEN banner LIKE "NF" AND rgn_nm_en LIKE "%West" THEN "nofrillsw"
    WHEN banner LIKE "PRO" THEN "provigo"
    WHEN banner LIKE "RASS" THEN "rass"
    WHEN banner LIKE "RCSO" THEN "superstoreo"
    WHEN banner LIKE "RCSW" THEN "superstorew"
    WHEN banner LIKE "YIG%" AND rgn_nm_en LIKE "%Atlantic" THEN "independenta"
    WHEN banner LIKE "YIG%" AND rgn_nm_en LIKE "%Ontario" THEN "independento"
    WHEN banner LIKE "YIG%" AND rgn_nm_en LIKE "%West" THEN "independentw"
    WHEN banner LIKE "RCWC" AND rgn_nm_en LIKE "%Atlantic" THEN "wholesalecluba"
    WHEN banner LIKE "RCWC" AND rgn_nm_en LIKE "%Ontario" THEN "wholesaleclubo"
    WHEN banner LIKE "RCWC" AND rgn_nm_en LIKE "%Quebec" THEN "wholesaleclubq"
    WHEN banner LIKE "RCWC" AND rgn_nm_en LIKE "%West" THEN "wholesaleclubw"
    WHEN banner LIKE "ZEHRS" THEN "zehrs"
    END AS new_query_banner,
FROM f
LEFT JOIN s ON f.pur_org_num = s.rgn_num AND f.dist_chnnl_num = s.dist_chnnl_num