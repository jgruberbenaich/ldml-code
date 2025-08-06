WITH

d AS (
  SELECT DATE('2025-04-20') AS dt -- REPLACE WITH RELEVANT FILEDATE FROM INSTABUG_MERCH_REPOSITORY GOOGLE SHEET
),

prep AS (
SELECT dt, BugCategory, Status, Number, Duplicate,
  MIN(FileDate) AS earliest_status,
FROM `ld-pcx-bia.jongrub.instabug_reporting_testing`
,d
GROUP BY ALL
HAVING MIN(FileDate) = dt
)

SELECT Status, BugCategory, 
  COUNTIF(Duplicate IS FALSE) AS unique_tickets,
  COUNT(DISTINCT Number) AS total_tickets
FROM prep
GROUP BY ALL
ORDER BY Status, BugCategory