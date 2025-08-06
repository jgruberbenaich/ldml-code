CREATE OR REPLACE FUNCTION `ld-pcx-bia.jongrub.check_digit`(UPC STRING)
RETURNS STRUCT<gtin14 STRING, gtin_without_last_digit STRING, check_digit STRING, gtin_with_check_digit STRING>
LANGUAGE js AS """
  // Step 1: Check for non-numeric characters
  if (!/^[0-9]+$/.test(UPC)) {
    return null;
  }

  // Step 2: Left pad with zeros
  const gtin14 = UPC.padStart(14, '0');

  // Step 3: Truncate to 13 digits
  const gtin_without_last_digit = gtin14.substring(0, 13);

  // Step 4: Sum of digits in even positions (0-based indexing)
  let evenSum = 0;
  for (let i = 1; i < gtin_without_last_digit.length; i += 2) {
    evenSum += parseInt(gtin_without_last_digit[i]);
  }

  // Step 5: Sum of digits in odd positions, multiplied by 3
  let oddSumTimes3 = 0;
  for (let i = 0; i < gtin_without_last_digit.length; i += 2) {
    oddSumTimes3 += parseInt(gtin_without_last_digit[i]);
  }
  oddSumTimes3 *= 3;

  // Step 6: Total sum
  const totalSum = evenSum + oddSumTimes3;

  // Step 7: Round up to the nearest 10
  const roundedSum = Math.ceil(totalSum / 10) * 10;

  // Step 8: Calculate the check digit
  const checkDigit = roundedSum - totalSum;

  // Step 9: Concatenate gtin_without_last_digit and checkDigit
  const gtin_with_check_digit = gtin_without_last_digit + checkDigit;

  return {
    gtin14: gtin14,
    gtin_without_last_digit: gtin_without_last_digit,
    check_digit: checkDigit.toString(),
    gtin_with_check_digit: gtin_with_check_digit
  };
""";

SELECT `ld-pcx-bia.jongrub`.check_digit('6291041500214')