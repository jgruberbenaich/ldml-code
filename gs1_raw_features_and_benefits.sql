SELECT
 LTRIM(h.identification.gtin,'0') AS UPC,
  rec_cre_tms,
  rec_chng_tms,
  brandownerversioncode,
  e.identification.systemversion,
  productnameenglish,
  brandownerproductmarketingmessageenglish,
  featuresandbenefits,
  trademarkinformationenglish,
  TIMESTAMP_DIFF(rec_chng_tms, TIMESTAMP(e.identification.systemversion), DAY) AS delay
FROM `lt-dia-lake-prd-raw.product.gs1_ecommerce_content_hist` h -- PROD RAW
LEFT JOIN UNNEST(ecommercecontent) e
LEFT JOIN UNNEST(featuresandbenefits) fb
#WHERE fb.featuresandbenefitsenglish IS NOT NULL
#QUALIFY RANK() OVER (PARTITION BY h.identification.gtin ORDER BY rec_cre_tms DESC, rec_chng_tms DESC, e.identification.systemversion DESC) = 1
WHERE LTRIM(h.identification.gtin,'0') ="64100144507"
ORDER BY systemversion DESC, rec_chng_tms DESC, rec_cre_tms DESC