-- Josh's S&E Ask
WITH

current_dates AS (
  SELECT promo_wk AS curr_promo_wk,
    promo_yr AS curr_promo_yr,
    wk AS curr_wk,
    yr AS curr_yr,
    DATE_TRUNC(CURRENT_DATE("EST"), WEEK(SATURDAY)) AS TY_timeframe_end,
    DATE_SUB(DATE_TRUNC(CURRENT_DATE("EST"), WEEK(SATURDAY)), INTERVAL 48 WEEK) AS LY_timeframe_end
  FROM `ld-pcx-bia.dim.dates` 
  WHERE cal_date = CURRENT_DATE("EST")
  ),


dt AS (
  SELECT cal_date, wk, pd, qtr, yr, promo_wk, promo_yr, TY_timeframe_end, LY_timeframe_end
  FROM `ld-pcx-bia.dim.dates`
    ,current_dates
  WHERE (promo_wk>= 39 AND yr IN (2023,2024)) -- Include previous years' data starting wk39
    OR (wk < (curr_wk+4) AND yr = 2024) -- Include LY data for previous weeks + 4 future weeks
    OR (wk < curr_wk AND yr = 2025) -- Include CY data for all previous weeks
  ORDER BY 1 DESC
  ), 

st AS (
  -- details for all active pcx-enabled stores
  SELECT LPAD(hub_store_number,4,'0') AS store_number,
    division, 
    banner,
    CASE 
      WHEN banner = 'RCSO' THEN DATE('2024-09-26') -- S&E start date at RCSO
      WHEN division IN ('Core Market','Superstore') THEN DATE('2024-12-19') -- S&E start date at remaining SuperMarket banners
      WHEN division = 'Hard Discount' THEN DATE('2025-01-09') -- S&E start date at Hard Discount
    END AS se_start_date,
    CASE 
      WHEN banner = 'RCSO' THEN DATE('2023-09-28') -- 52 weeks before S&E start date at RCSO
      WHEN division IN ('Core Market','Superstore') THEN DATE('2023-12-17') -- 52 weeks before S&E start date at remaining SuperMarket banners
      WHEN division = 'Hard Discount' THEN DATE('2024-01-11') -- 52 weeks before S&E start date at Hard Discount
    END AS se_YOY_start_date,

  FROM `ld-pcx-bia.dim.stores_flip`
  WHERE 1=1
    AND active_date <= '2024-09-26' -- Stores active during the S&E period
    AND LENGTH(store_number) <= 4
    AND og_close_date > '2024-09-26'
    AND division IN ('Core Market','Superstore','Hard Discount') -- S&E divisions only
  ),

mch AS ( -- Find MCH cd for all existing MCHs within the 5 known S&E categories
  SELECT DISTINCT
    mch_3_desc_en AS mch_3,
    mch_2_desc_en AS mch_2,
    mch_1_desc_en AS mch_1,
    mch_0_desc_en AS mch_0,
    mch_0_cd AS mch_cd
  FROM `ld-ds-bi-analytics-prod.cerebro_reporting.sap_ecc_mara`
  JOIN `lt-dia-lake-prd-consume.product.article_curr` ON LTRIM(matnr,'0') = artcl_num
  WHERE LEFT(MATKL,7) IN (
    'M102112', -- Household Paper Products
    'M102501', -- Natural Foods
    'M102111', -- Household Cleaning Needs
    'M100201', -- Baby
    'M102113') -- Pet Food & Supplies
  ),

vendor AS(
  --Identifies vendor-article relationships
  SELECT STRING_AGG(DISTINCT IFNULL(rolodex_name,vend_nm)) AS vendor_name, 
    vd.artcl_num AS article_number, 
  FROM `ld-ds-bi-analytics-prod.bi_dw.vendor_determination` vd
  LEFT JOIN `ld-pcx-bia.Merch_PIM.SUPPLIER_ROLODEX` ON vd.vend_num = vendor_number
  LEFT JOIN `ld-pcx-bia.Merch_PIM.SUPPLIER_SCORECARD_EXCLUSIONS` x ON vd.artcl_num = x.article_number AND LTRIM(vd.vend_num,'0')=LTRIM(x.vendor_number,'0')
  WHERE x.article_number IS NULL
    AND vend_num <> "9999999999"
  GROUP BY ALL),

pt AS (
  SELECT LTRIM(MATNR,'0') AS article_number,
    artcl_med_desc_en AS sap_desc,
    mch_3,
    mch_2,
    mch_1,
    mch_0,
    mch_cd,
    vendor_name
  FROM `ld-ds-bi-analytics-prod.cerebro_reporting.sap_ecc_mara`
    JOIN mch ON MATKL = mch_cd
    LEFT JOIN `lt-dia-lake-prd-consume.product.article_curr` art ON LTRIM(matnr,'0') = art.artcl_num
    LEFT JOIN vendor ON LTRIM(matnr,'0') = vendor.article_number
),

og AS (
  SELECT
    yr, wk, promo_yr, promo_wk,
    CASE 
      WHEN banner = 'RCSO' AND transaction_dt BETWEEN se_start_date AND TY_timeframe_end THEN "TY" -- S&E start date at RCSO
      WHEN division IN ('Core Market','Superstore') AND transaction_dt BETWEEN se_start_date AND TY_timeframe_end THEN "TY" -- S&E start date at remaining SuperMarket banners
      WHEN division = 'Hard Discount' AND transaction_dt BETWEEN se_start_date AND TY_timeframe_end THEN "TY" -- S&E start date at Hard Discount
      WHEN banner = 'RCSO' AND transaction_dt BETWEEN se_YOY_start_date AND LY_timeframe_end THEN "LY" -- 52 weeks before S&E start date at RCSO
      WHEN division IN ('Core Market','Superstore') AND transaction_dt BETWEEN se_YOY_start_date AND LY_timeframe_end THEN "LY" -- 52 weeks before S&E start date at remaining SuperMarket banners
      WHEN division = 'Hard Discount' AND transaction_dt BETWEEN se_YOY_start_date AND LY_timeframe_end THEN "LY" -- 52 weeks before S&E start date at Hard Discount
      END AS year_cat,
    division, 
    banner,
    CONCAT(article_id,'_',og.sales_uom_cd) AS liam,
    SUM(sales_amt) AS og_sales,
    SUM(sales_qty) AS og_qty,
    SUM(gp_amt) AS og_profit,
    SUM(IF(fulfillment_type IN ('PCX Delivery','PCX Pickup'),sales_amt,0)) AS pcx_sales,
    SUM(IF(fulfillment_type IN ('PCX Delivery','PCX Pickup'),sales_qty,0)) AS pcx_qty,
    SUM(IF(fulfillment_type IN ('PCX Delivery','PCX Pickup'),gp_amt,0)) AS pcx_profit
  FROM `ld-ds-bi-analytics-prod.bi_reporting.sl_trans_qlfy_ecom_dly` og -- ecom transactions
    JOIN dt ON og.transaction_dt = dt.cal_date -- dates specified above
    JOIN st ON LPAD(og.site_id,4,'0') = st.store_number -- stores specified above
    JOIN pt ON article_number = article_id
  WHERE transaction_dt >= '2023-09-01'
    AND article_id LIKE '2%'
    AND article_acct_assn_grp_cd IN ('01','21') -- Always use this filter on ecom
    AND fulfillment_type IN ('PCX Delivery','PCX Pickup','Instacart','DD Marketplace') -- Exclude JFSFS and LD-Marketplace
  GROUP BY ALL
),

rtl AS (
  SELECT
    yr, wk,promo_yr, promo_wk,
    CASE 
      WHEN banner = 'RCSO' AND trans_dt BETWEEN se_start_date AND TY_timeframe_end THEN "TY" -- S&E start date at RCSO
      WHEN division IN ('Core Market','Superstore') AND trans_dt BETWEEN se_start_date AND TY_timeframe_end THEN "TY" -- S&E start date at remaining SuperMarket banners
      WHEN division = 'Hard Discount' AND trans_dt BETWEEN se_start_date AND TY_timeframe_end THEN "TY" -- S&E start date at Hard Discount
      WHEN banner = 'RCSO' AND trans_dt BETWEEN se_YOY_start_date AND LY_timeframe_end THEN "LY" -- 52 weeks before S&E start date at RCSO
      WHEN division IN ('Core Market','Superstore') AND trans_dt BETWEEN se_YOY_start_date AND LY_timeframe_end THEN "LY" -- 52 weeks before S&E start date at remaining SuperMarket banners
      WHEN division = 'Hard Discount' AND trans_dt BETWEEN se_YOY_start_date AND LY_timeframe_end THEN "LY" -- 52 weeks before S&E start date at Hard Discount
      END AS year_cat,
    division, banner,
    CONCAT(artcl_num,'_',sl_uom_cd) AS liam,
    SUM(prrtd_pstd_sl_amt) AS rtl_sales,
    SUM(prrtd_pstd_sl_qty) AS rtl_qty,
    SUM(SAFE_SUBTRACT(prrtd_pstd_sl_amt,prrtd_pstd_ext_gp_cost)) AS rtl_margin
  FROM `lt-dia-lake-prd-consume.financial_reporting.sales_lcl_store_article_dly` rtl -- instore + online transactions
    JOIN dt ON rtl.trans_dt = dt.cal_date -- dates specified above
    JOIN st ON LPAD(rtl.site_num,4,'0') = st.store_number -- stores specified above
    JOIN pt ON rtl.artcl_num = article_number
  WHERE trans_dt >= '2023-09-01'
    AND artcl_num LIKE '2%'
    AND artcl_acct_assn_grp_cd IN ('01','21') -- Always use this filter on ecom
  GROUP BY ALL
),

pcs AS (
  SELECT DISTINCT
    liam AS pcs_liam,
    -- Multi-line PCX name as it appears on PDP
      IF(brand.brand_displayable = TRUE,brand.name_en||'\n','') -- If brand is displayable show brand and space otherwise don't show the brand
      || name_en ||' '||'\n'|| -- Product title,
      IF(attributes.items_per_package>1,CAST(attributes.items_per_package AS STRING)||'x ','')||  -- If multiple items per package show the number otherwise skip
      CASE 
        WHEN selling_type = "SOLD_BY_EACH"
          THEN CAST(attributes.item_size AS STRING)||' '||attributes.item_size_uom -- For items priced+sold by each, use item size
        WHEN selling_type = "SOLD_BY_WEIGHT"
          THEN 'per ' || CAST(attributes.sold_by_unit AS STRING) || CAST(attributes.sold_by_uom AS STRING) -- For items priced+sold by weight, use ATC size
        WHEN selling_type = "SOLD_BY_EACH_PRICED_BY_WEIGHT"
          THEN'about '||CAST(attributes.estimated_typical_weight AS STRING)||'KG' -- For items priced by weight sold by each, use estimated size
        END AS pcx_title,
    ARRAY_TO_STRING(tags, ' | ') AS pcs_tags
  FROM `ld-ds-bi-analytics-prod.product_catalog.products`
  WHERE status = 'APPROVED'
    AND liam LIKE '2%'
)

SELECT * EXCEPT(pcs_liam), IFNULL(UPPER(pcs_tags),'') LIKE '%SUBSCRIBE%' AS is_se,
FROM rtl
  FULL JOIN og USING (yr, wk, promo_wk, promo_yr, year_cat, liam,division,banner)
  INNER JOIN pt ON SPLIT(liam,'_')[OFFSET(0)] = pt.article_number
  LEFT JOIN pcs ON IFNULL(rtl.liam, og.liam) = pcs_liam
WHERE year_cat IS NOT NULL