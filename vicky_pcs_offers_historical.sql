-- Vicky ask
-- historical is_assorted data from pcs offers

SELECT liam, 
  is_assorted,
  vendor.store_id,
  insertTime, -- timestamp from when this record was 
  publishTime -- timestamp from when this record was published from PCS, similar but not equal to the timestamp when the change was made
FROM `ld-ds-bi-analytics-prod.product_catalog.offers_pcs_test`
WHERE liam IN ('20310093_EA') -- Replace with whatever liams you are looking for
ORDER BY liam,store_id, publishTime DESC