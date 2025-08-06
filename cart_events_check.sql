SELECT 
  CONCAT(c.product_article_number,"_",product_uom) AS liam,
  c.user_event_name,
  c.platform,
  c.device_user_id,
  c.domain_userid,
  c.derived_tstamp,
  c.collector_tstamp,
  o.cart_id,
  o.order_number,
  h.order_creation_time,
  h.last_modified_time,
  h.pickup_end_date,
  h.store_number,
FROM `ld-ds-bi-analytics-prod.snowplow_analytics.snowplow_unioned_cart_events` c
JOIN `ld-ds-bi-analytics-prod.snowplow_analytics.snowplow_unioned_orders` o USING(session_id)
JOIN `ld-ds-bi-analytics-prod.bi_dw.pcx_helios_orders` h USING(order_number)
WHERE 1=1
  AND DATE(c.collector_tstamp) >= '2025-05-01'
  AND CONCAT(c.product_article_number,"_",product_uom) = "21538137_EA"
ORDER BY cart_id, pickup_end_date, order_number, derived_tstamp