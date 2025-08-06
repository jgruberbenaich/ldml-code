SELECT 
LPAD(store_number,4,'0') AS store_number,
banner_code,
banner_division AS division,
address,
city,
province,
postal_code,
CASE 
    WHEN store_name LIKE "%City%Market%" THEN CONCAT("https://www.independentcitymarket.ca/store-locator/details/",LPAD(store_number,4,'0')) -- Independent City Market stores that are listed as VM
    WHEN store_number IN ('4429','7155','7491') -- Loblaws West stores that are listed as YIGW
      OR banner_code = 'LOB'THEN CONCAT("https://www.loblaws.ca/store-locator/details/",LPAD(store_number,4,'0'))
    WHEN banner_code = 'DOM'THEN CONCAT("https://www.newfoundlandgrocerystores.ca/store-locator/details/",LPAD(store_number,4,'0'))
    WHEN banner_code = 'EF'THEN CONCAT("https://www.extrafoods.ca/store-locator/details/",LPAD(store_number,4,'0'))
    WHEN banner_code = 'FORT'THEN CONCAT("https://www.fortinos.ca/store-locator/details/",LPAD(store_number,4,'0'))
    WHEN banner_code = 'MAXI'THEN CONCAT("https://www.maxi.ca/store-locator/details/",LPAD(store_number,4,'0'))
    WHEN banner_code = 'NF'THEN CONCAT("https://www.nofrills.ca/store-locator/details/",LPAD(store_number,4,'0'))
    WHEN banner_code = 'PRO'THEN CONCAT("https://www.provigo.ca/store-locator/details/",LPAD(store_number,4,'0'))
    WHEN banner_code = 'RASS'THEN CONCAT("https://www.atlanticsuperstore.ca/store-locator/details/",LPAD(store_number,4,'0'))
    WHEN banner_code = 'RCS'THEN CONCAT("https://www.realcanadiansuperstore.ca/store-locator/details/",LPAD(store_number,4,'0'))
    WHEN banner_code = 'RCWC'THEN CONCAT("https://www.wholesaleclub.ca/store-locator/details/",LPAD(store_number,4,'0'))
    WHEN banner_code = 'VM'THEN CONCAT("https://www.valumart.ca/store-locator/details/",LPAD(store_number,4,'0'))
    WHEN banner_code = 'YIG'THEN CONCAT("https://www.yourindependentgrocer.ca/store-locator/details/",LPAD(store_number,4,'0'))
    WHEN banner_code = 'ZEHRS'THEN CONCAT("https://www.zehrs.ca/store-locator/details/",LPAD(store_number,4,'0'))
    WHEN banner_code = 'ZEHRS'THEN CONCAT("https://www.zehrs.ca/store-locator/details/",LPAD(store_number,4,'0')) 
  END AS store_link
FROM `ld-ds-bi-analytics-prod.bi_reporting.pcx_stores`
WHERE 1=1
  AND LOWER(TRIM(banner_name)) NOT IN ('unknown','joe fresh','tt','real canadian liquor store')
  AND CHAR_LENGTH(store_number) <= 4
  AND og_close_date > CURRENT_DATE()
  AND active_date <= CURRENT_DATE()
  AND LPAD(store_number,4,'0') IN ('0202') -- enter individual stores of interest, or remove this line entirely
ORDER BY 1