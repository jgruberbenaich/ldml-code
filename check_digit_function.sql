WITH

prep_1 AS (
  SELECT 
    ean11, -- original barcode found in SAP
    LPAD(ean11,14,'0') AS gtin_14, -- original barcode with leading zeros added to make it 14 digits
    LEFT(LPAD(ean11,14,'0'),13) AS gtin_reposition, -- the first 13 digits of the 14 digit barcode
    SPLIT(LEFT(LPAD(ean11,14,'0'),13),"") AS ean11_array -- convert the first 13 digits into an array for easy calculations
  FROM `ld-ds-bi-analytics-prod.cerebro_reporting.sap_ecc_mean`
  WHERE 1=1
    AND deleted_flag IS FALSE
    AND STARTS_WITH(LTRIM(matnr,'0'),'2')
),

prep_2 AS (
  SELECT *,
    ARRAY_AGG(STRUCT(
      SAFE_CAST(digit AS SMALLINT) AS digit_value,
      OFFSET+1 AS digit_position,
      CASE 
        WHEN MOD(OFFSET+1,2)=0 THEN "EVEN"
        WHEN MOD(OFFSET+1,2)<>0 THEN "ODD" END AS digit_type) ORDER BY OFFSET) AS d
  FROM prep_1
    LEFT JOIN UNNEST (ean11_array) AS digit
    WITH OFFSET
  GROUP BY ALL
),

prep_3 AS (
  SELECT ean11,
    -- sum of all the digits in ODD positions
    SUM(IF(digit_type = "ODD",digit_value,0)) AS odd_sum,

    -- (sum of all the digits in ODD positions) * 3
    SUM(IF(digit_type = "ODD",digit_value,0))*3 AS odd_sum_product,
    
    -- sum of all the digits in EVEN positions
    SUM(IF(digit_type = "EVEN",digit_value,0)) AS even_sum,
    
    -- sum of the odd position digits * 3 and even digits
    SUM(IF(digit_type = "EVEN",digit_value,0)) + SUM(IF(digit_type = "ODD",digit_value,0))*3 AS all_digits_sum_product, 
    
    -- sum of the odd position digits * 3 and even digits rounded up to the nearest 10
    CEIL((SUM(IF(digit_type = "EVEN",digit_value,0)) + SUM(IF(digit_type = "ODD",digit_value,0))*3)/10)*10 AS nearest_ten,
    
    -- check_digit = nearest_ten MINUS all_digits_sum_product
    CEIL((SUM(IF(digit_type = "EVEN",digit_value,0)) + SUM(IF(digit_type = "ODD",digit_value,0))*3)/10)*10 
    - (SUM(IF(digit_type = "EVEN",digit_value,0)) + SUM(IF(digit_type = "ODD",digit_value,0))*3) AS check_digit,

    -- new gtin where last digit is replaced with check digit
    CONCAT(LEFT(LPAD(ean11,14,'0'),13), -- repositioned gtin without last digit
      CEIL((SUM(IF(digit_type = "EVEN",digit_value,0)) + SUM(IF(digit_type = "ODD",digit_value,0))*3)/10)*10
      - (SUM(IF(digit_type = "EVEN",digit_value,0)) + SUM(IF(digit_type = "ODD",digit_value,0))*3)) -- check digit
      AS gtin_14_with_check_digit
  FROM prep_2
  LEFT JOIN UNNEST(d)
  GROUP BY ALL
)

SELECT *
FROM `ld-ds-bi-analytics-prod.cerebro_reporting.sap_ecc_mean`
JOIN prep_3 USING(ean11)
