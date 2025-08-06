SELECT DATE(start_time) AS rundate,
  COUNT(*)
FROM
  `region-northamerica-northeast1`.INFORMATION_SCHEMA.JOBS_BY_USER
WHERE query LIKE "%`ld-pcx-bia.Merch_PIM.PCX_PRODUCT_INFORMATION_DASHBOARD`%"
GROUP BY ALL