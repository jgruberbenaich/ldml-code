CREATE OR REPLACE FUNCTION `ld-pcx-bia.jongrub.check_digit`(UPC STRING) RETURNS STRING LANGUAGE js AS R"""
// Step 1: Check for non-numeric characters
  if (!/^[0-9]+$/.test(UPC)) {
    return null;
  }

  // Step 2: Left pad with zeros
  const gs1_key = UPC.padStart(13, '0');

  // Step 3: Sum of digits in even positions (0-based indexing)
  let evenSum = 0;
  for (let i = 1; i < gs1_key.length; i += 2) {
    evenSum += parseInt(gs1_key[i]);
  }

  // Step 4: Sum of digits in odd positions, multiplied by 3
  let oddSumTimes3 = 0;
  for (let i = 0; i < gs1_key.length; i += 2) {
    oddSumTimes3 += parseInt(gs1_key[i]);
  }
  oddSumTimes3 *= 3;

  // Step 5: Total sum
  const totalSum = evenSum + oddSumTimes3;

  // Step 6: Round up to the nearest 10
  const roundedSum = Math.ceil(totalSum / 10) * 10;

  // Step 7: Calculate the check digit
  const checkDigit = roundedSum - totalSum;

  return checkDigit.toString();
""";