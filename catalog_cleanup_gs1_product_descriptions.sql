# GS1 gapfill - find active articles with no description_en and match them with GS1 eComm vault brandowner message
# active national brand items with no descriptions/short descriptions
CREATE TEMP FUNCTION convertToHTML(input_string STRING) RETURNS STRING
LANGUAGE js AS """
  if (input_string === null) {
    return '';
  }
  // Check if there are any line breaks
  if (input_string.indexOf('\\n') === -1) {
    // No line breaks, wrap the string in <p> and </p> tags
    return '<p>' + input_string + '</p>';
  }
  
  // Split the input string into an array of lines
  let lines = input_string.split('\\n');
  
  // Create an unordered list HTML string
  let htmlList = '<ul>';
  lines.forEach(line => {
    // Trim leading and trailing whitespace from each line
    let trimmedLine = line.trim();
    
    // Check if the line starts with a bullet point symbol
    if (/^[-·–•.]/.test(trimmedLine)) {
      // Remove the bullet point symbol from the line
      trimmedLine = trimmedLine.substring(1).trim();
    }
    
    // Skip empty lines
    if (trimmedLine !== '') {
      // Add each line as a list item to the HTML string
      htmlList += '<li>' + trimmedLine + '</li>';
    }
  });
  htmlList += '</ul>';
  
  return htmlList;
""";

WITH pcs AS (
  SELECT liam,
    article_number,
    CONCAT(IF(brand.brand_displayable=TRUE,CONCAT(brand.name_en," "),''),
      name_en, " ", 
      IF(attributes.items_per_package > 1, CONCAT(CAST(attributes.items_per_package AS STRING),"x"),""),
      attributes.item_size, 
      attributes.item_size_uom) AS long_name_en,
    CONCAT(IF(brand.brand_displayable=TRUE,CONCAT(brand.name_fr," "),''),
      name_fr, " ", 
      IF(attributes.items_per_package > 1, CONCAT(CAST(attributes.items_per_package AS STRING),"x"),""),
      attributes.item_size, 
      attributes.item_size_uom) AS long_name_fr, -- Product tile details
      description_en,
      description_fr,
      total_stores
  FROM `ld-ds-bi-analytics-prod.product_catalog.products`
  JOIN `ld-pcx-bia.Merch_PIM.PCX_ACTIVE_ARTICLE_STORES` USING(article_number) -- Active items only
  WHERE status = "APPROVED"
    AND liam LIKE "2%"
    AND brand.brand_displayable = TRUE
    AND brand.control_brand = FALSE -- Displayable National Brands only
    AND (LENGTH(IFNULL(description_fr,"")) < 100 OR LENGTH(IFNULL(description_fr,"")) < 100) -- Missing or short descriptions only
),

gs1 AS (
  SELECT DISTINCT gtin_cd AS UPC,
    brnd_own_prod_mkt_eng_msg,
    addedfeat_and_bnft_eng_desc,
    CHAR_LENGTH(brnd_own_prod_mkt_eng_msg) AS mm_en_len,
    REGEXP_CONTAINS(brnd_own_prod_mkt_eng_msg,"\n") AS mm_en_break,
    CHAR_LENGTH(addedfeat_and_bnft_eng_desc) AS FAB_en_len,
    REGEXP_CONTAINS(addedfeat_and_bnft_eng_desc,"\n") AS fab_en_break,
    IFNULL(CONCAT(REPLACE(REGEXP_REPLACE(ConvertToHTML(brnd_own_prod_mkt_eng_msg),"\n","</p><p>"),"</p><p></p>","</p>")),"") AS clean_mm_en,
    ConvertToHTML(addedfeat_and_bnft_eng_desc) AS clean_fab_en,
    brnd_own_prod_mkt_fr_msg,
    addedfeat_and_bnft_fr_desc,
    CHAR_LENGTH(brnd_own_prod_mkt_fr_msg) AS PMM_fr_len,
    REGEXP_CONTAINS(brnd_own_prod_mkt_fr_msg,"\n") AS mm_fr_break, 
    CHAR_LENGTH(addedfeat_and_bnft_fr_desc) AS FAB_fr_len,
    REGEXP_CONTAINS(addedfeat_and_bnft_fr_desc,"\n") AS fab_fr_break,
    IFNULL(CONCAT(REPLACE(REGEXP_REPLACE(ConvertToHTML(brnd_own_prod_mkt_fr_msg),"\n","</p><p>"),"</p><p></p>","</p>")),"") AS clean_mm_fr,
    ConvertToHTML(addedfeat_and_bnft_fr_desc) AS clean_fab_fr,
    
  FROM `lt-dia-lake-prd-consume.product.ecommerce_content_curr`
  WHERE CHAR_LENGTH(brnd_own_prod_mkt_fr_msg) > 0
    OR CHAR_LENGTH(brnd_own_prod_mkt_eng_msg) > 0
)

SELECT DISTINCT pcs.*,
  gs1.*,
  CASE WHEN CHAR_LENGTH(description_en) > 100 THEN description_en
    WHEN addedfeat_and_bnft_eng_desc = brnd_own_prod_mkt_eng_msg THEN clean_fab_en
    ELSE CONCAT(clean_mm_en, clean_fab_en) END AS gs1_desc_en,
  CASE WHEN CHAR_LENGTH(description_fr) > 100 THEN description_fr 
    WHEN addedfeat_and_bnft_fr_desc = brnd_own_prod_mkt_fr_msg THEN clean_fab_fr
    ELSE CONCAT(clean_mm_fr, clean_fab_fr) END AS gs1_desc_fr
FROM pcs
  JOIN `ld-ds-bi-analytics-prod.cerebro_reporting.sap_ecc_mean` ON liam = CONCAT(LTRIM(matnr,'0'),"_",meinh)
  JOIN gs1 ON ean11 = UPC
WHERE (CHAR_LENGTH(IFNULL(description_en,"")) < 100 AND CHAR_LENGTH(CONCAT(clean_mm_en, clean_fab_en)) > 1)
  OR (CHAR_LENGTH(IFNULL(description_fr,"")) < 100 AND CHAR_LENGTH(CONCAT(clean_mm_fr, clean_fab_fr)) > 1)
ORDER BY total_stores DESC