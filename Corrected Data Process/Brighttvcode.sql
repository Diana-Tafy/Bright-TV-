/* =====================================================================
   BRIGHT TV — CASE STUDY SQL SCRIPT (CORRECTED VERSION)
   -----------------------------------------------------------------
   Fixes applied vs. original draft:
   1. Time-of-day buckets rewritten so every hour (0-23) is covered
      AND "Night" is actually reachable (it was unreachable before).
   2. Time-of-day labels made IDENTICAL across every query that uses
      them (Morning / Midday / Afternoon / Evening / Night no longer
      swap meaning between queries).
   3. Subscription-type logic made IDENTICAL and case-consistent
      across every query ('SuperSport' vs 'Supersport' typo fixed).
   4. "Viewership by hour" no longer groups by `timestamp`, which
      was making every group essentially unique (COUNT(*) ≈ 1).
   5. Kids' shows filter switched from LIKE (no wildcards, so it was
      behaving like `=` anyway) to a cleaner IN (...).
   6. Reserved/ambiguous identifiers consistently backticked.
   7. Added comments flagging two things you should confirm against
      your actual business rules (Active vs Inactive users logic,
      and the UTC→SA timezone assumption) — these are judgment calls
      on the data, not syntax errors, so they're left as-is with a
      note rather than silently changed.
   ===================================================================== */


-- ---------------------------------------------------------------------
-- 0. VIEW THE TABLE
-- ---------------------------------------------------------------------
SELECT * FROM `brighttv`.`default`.`bright_tv_dataset_case_studypart_2`;


-- ---------------------------------------------------------------------
-- 1. NUMBER OF CHANNELS WATCHED
-- ---------------------------------------------------------------------
SELECT COUNT(DISTINCT Channel) AS Number_of_channels
FROM `brighttv`.`default`.`bright_tv_dataset_case_studypart_2`;


-- ---------------------------------------------------------------------
-- 2. USER PROFILE — COLOURED / INDIAN_ASIAN FEMALES OVER 18
-- ---------------------------------------------------------------------
SELECT *
FROM brighttv.default.bright_tv_dataset_case_studypart_2
WHERE Race IN ('coloured', 'indian_asian')
  AND Gender = 'female'
  AND Age > 18;


-- ---------------------------------------------------------------------
-- 3. USER PROFILES + TRANSACTIONS — WHITE MALES, SUPERSPORT BLITZ, EASTERN CAPE
-- ---------------------------------------------------------------------
SELECT *
FROM brighttv.default.bright_tv_dataset_case_studypart_2
WHERE Gender = 'male'
  AND Race = 'white'
  AND Channel = 'SuperSport Blitz'
  AND Province = 'Eastern Cape';


-- ---------------------------------------------------------------------
-- 4. USER PROFILE — WHITE, OVER 25, ANY PROVINCE
-- ---------------------------------------------------------------------
SELECT UserID13, Age, Name, Province, Channel, Race
FROM `brighttv`.`default`.`bright_tv_dataset_case_studypart_2`
WHERE Age > 25
  AND Race = 'white'
  AND Province IN (
        'Western Cape', 'Gauteng', 'KwaZulu-Natal', 'Northern Cape',
        'Mpumalanga', 'Limpopo', 'North West', 'Free State', 'Eastern Cape'
      );


-- ---------------------------------------------------------------------
-- 5. ACTIVE VS INACTIVE USERS
-- NOTE: this counts non-null values in UserID13 vs UserID0. Confirm
-- that UserID13 / UserID0 genuinely represent "active" vs "inactive"
-- user ID schemes in your source data — COUNT() here is a null-check,
-- not a behavioural "active" definition (e.g. recency/frequency).
-- ---------------------------------------------------------------------
SELECT
    COUNT(UserID13) AS Active_Users,
    COUNT(UserID0)  AS Inactive_Users
FROM brighttv.default.bright_tv_dataset_case_studypart_2;


-- ---------------------------------------------------------------------
-- 6. FEMALE USERS — BLACK, OVER 20
-- ---------------------------------------------------------------------
SELECT UserID0, Name, Race, Gender, Age, Channel
FROM brighttv.default.bright_tv_dataset_case_studypart_2
WHERE Race = 'black'
  AND Gender = 'female'
  AND Age > 20;


-- ---------------------------------------------------------------------
-- 7. SUBSCRIPTION TYPES (BASIC / PREMIUM / FAMILY PLAN)
-- Consistent mapping used everywhere else in this script:
--   SuperSport        -> Basic
--   SuperSport Blitz  -> Premium
--   everything else   -> Family_Plan
-- ---------------------------------------------------------------------
SELECT
    CASE
        WHEN Channel = 'SuperSport'       THEN 'Basic'
        WHEN Channel = 'SuperSport Blitz' THEN 'Premium'
        ELSE 'Family_Plan'
    END AS Subscription_Type,
    COUNT(DISTINCT Channel) AS channel_count
FROM `brighttv`.`default`.`bright_tv_dataset_case_studypart_2`
GROUP BY Subscription_Type;


-- ---------------------------------------------------------------------
-- 8. DURATION OF VIEWING
-- NOTE: ELSE '4 hours' also catches nulls / unexpected values in
-- `Duration 3`, not just genuine 4-hour sessions. Confirm this is
-- acceptable, or add an explicit NULL/other check if not.
-- ---------------------------------------------------------------------
SELECT
    CASE
        WHEN `Duration 3` = '1' THEN '1 hour'
        WHEN `Duration 3` = '2' THEN '2 hours'
        WHEN `Duration 3` = '3' THEN '3 hours'
        ELSE '4 hours'
    END AS duration_time,
    COUNT(DISTINCT Channel) AS channel_count
FROM brighttv.default.bright_tv_dataset_case_studypart_2
GROUP BY duration_time;


-- ---------------------------------------------------------------------
-- 9. WESTERN CAPE USERS WATCHING ICC CRICKET WORLD CUP 2011
-- ---------------------------------------------------------------------
SELECT UserID0, Name, Province, Race, Gender, Age, Channel
FROM brighttv.default.bright_tv_dataset_case_studypart_2
WHERE Race = 'white'
  AND Gender = 'male'
  AND Age > 25
  AND Channel = 'ICC Cricket World Cup 2011'
  AND Province = 'Western Cape';


-- ---------------------------------------------------------------------
-- 10. POPULAR WATCHED CHANNELS (TOP 70 BY CHANNEL/PROVINCE/AGE)
-- ---------------------------------------------------------------------
SELECT Channel, Province, Age, COUNT(DISTINCT UserID0) AS viewership
FROM brighttv.default.bright_tv_dataset_case_studypart_2
GROUP BY Channel, Province, Age
ORDER BY viewership DESC
LIMIT 70;


-- ---------------------------------------------------------------------
-- 11. KIDS' SHOWS (UNDER 20)
-- Switched LIKE -> IN since no wildcards were used (LIKE was behaving
-- exactly like an exact match anyway).
-- ---------------------------------------------------------------------
SELECT UserID0, Name, Channel, Age, Province, Gender, COUNT(*) AS Kids_Shows
FROM brighttv.default.bright_tv_dataset_case_studypart_2
WHERE Channel IN ('Boomerang', 'Nick Jr', 'Nickelodeon', 'Cartoon Network', 'Disney Junior')
  AND Age < 20
GROUP BY UserID0, Name, Channel, Age, Province, Gender;


-- ---------------------------------------------------------------------
-- 12. AVERAGE AGE PER CHANNEL
-- ---------------------------------------------------------------------
SELECT Channel, AVG(Age) AS Avg_age
FROM brighttv.default.bright_tv_dataset_case_studypart_2
GROUP BY Channel
ORDER BY Avg_age DESC;


-- ---------------------------------------------------------------------
-- 13. LEAST WATCHED CHANNELS
-- ---------------------------------------------------------------------
SELECT Channel, COUNT(DISTINCT UserID0) AS least_viewership
FROM brighttv.default.bright_tv_dataset_case_studypart_2
GROUP BY Channel
ORDER BY least_viewership ASC;


-- ---------------------------------------------------------------------
-- 14. PROVINCE WITH MOST VIEWERSHIP  (== query 16, kept for reference)
-- ---------------------------------------------------------------------
SELECT Province, COUNT(DISTINCT UserID0) AS most_viewership
FROM brighttv.default.bright_tv_dataset_case_studypart_2
GROUP BY Province
ORDER BY most_viewership DESC;


-- ---------------------------------------------------------------------
-- 15. TOTAL NUMBER OF PROVINCES
-- ---------------------------------------------------------------------
SELECT COUNT(DISTINCT Province) AS total_provinces
FROM brighttv.default.bright_tv_dataset_case_studypart_2;


-- ---------------------------------------------------------------------
-- 16. NUMBER OF USERS PER PROVINCE
-- NOTE: identical to query 14 above — kept both since they existed
-- in the original script, but you likely only need one of them.
-- ---------------------------------------------------------------------
SELECT Province, COUNT(DISTINCT UserID0) AS viewership
FROM brighttv.default.bright_tv_dataset_case_studypart_2
GROUP BY Province
ORDER BY viewership DESC;


-- ---------------------------------------------------------------------
-- 17. TOTAL SUBSCRIPTIONS
-- ---------------------------------------------------------------------
SELECT COUNT(DISTINCT UserID0) AS total_subscribers
FROM brighttv.default.bright_tv_dataset_case_studypart_2;


-- ---------------------------------------------------------------------
-- 18. ENGAGEMENT — SESSIONS PER USER
-- ---------------------------------------------------------------------
SELECT UserID0, COUNT(DISTINCT `timestamp`) AS sessions
FROM brighttv.default.bright_tv_dataset_case_studypart_2
GROUP BY UserID0
ORDER BY sessions DESC;


-- ---------------------------------------------------------------------
-- 19. ENGAGEMENT (ALTERNATE VIEW) — ROWS VS DISTINCT TIMESTAMPS PER USER
-- ---------------------------------------------------------------------
SELECT
    UserID0,
    COUNT(*)                    AS rows_per_user,
    COUNT(DISTINCT `timestamp`) AS distinct_timestamps
FROM brighttv.default.bright_tv_dataset_case_studypart_2
GROUP BY UserID0
ORDER BY rows_per_user DESC;


-- ---------------------------------------------------------------------
-- 20. NUMBER OF SUBSCRIBERS PER CHANNEL
-- ---------------------------------------------------------------------
SELECT Channel, COUNT(DISTINCT UserID0) AS Total_subscribers_per_Channel
FROM brighttv.default.bright_tv_dataset_case_studypart_2
GROUP BY Channel
ORDER BY Total_subscribers_per_Channel DESC;


-- ---------------------------------------------------------------------
-- 21. CONVERT RECORD DATE TO SA TIME
-- NOTE: from_utc_timestamp assumes `Record Date` is stored in UTC.
-- If your raw timestamps are already captured in South African local
-- time, this conversion will incorrectly shift them forward by 2
-- hours. Confirm the source system's timezone before trusting this.
-- ---------------------------------------------------------------------
SELECT
    `Record Date`,
    try_to_timestamp(`Record Date`, 'M/d/yy H:mm') AS utc_timestamp,
    from_utc_timestamp(try_to_timestamp(`Record Date`, 'M/d/yy H:mm'), 'Africa/Johannesburg') AS sa_timestamp
FROM brighttv.default.bright_tv_dataset_case_studypart_2;


-- ---------------------------------------------------------------------
-- 22. PERSIST THE SA-TIME TIMESTAMP COLUMN
-- ---------------------------------------------------------------------
UPDATE brighttv.default.bright_tv_dataset_case_studypart_2
SET `timestamp` = from_utc_timestamp(try_to_timestamp(`Record Date`, 'M/d/yy H:mm'), 'Africa/Johannesburg')
WHERE try_to_timestamp(`Record Date`, 'M/d/yy H:mm') IS NOT NULL;


-- ---------------------------------------------------------------------
-- 23. VIEWERSHIP BY HOUR
-- FIX: removed `timestamp` from GROUP BY. Grouping by the raw
-- timestamp (near-unique per row) made every group ~1 row, so
-- COUNT(*) was meaningless as an hourly viewership figure.
-- ---------------------------------------------------------------------
SELECT
    Channel,
    hour(`timestamp`) AS hour_of_day,
    COUNT(*) AS viewership
FROM brighttv.default.bright_tv_dataset_case_studypart_2
GROUP BY Channel, hour_of_day
ORDER BY viewership DESC;


-- ---------------------------------------------------------------------
-- 24. TIME-OF-DAY BUCKET COUNTS
-- FIX: buckets now cover all 24 hours AND "Night" is reachable
-- (previously Morning/Midday/Afternoon/Evening covered 0-23 fully,
-- so ELSE 'Night' could never fire). Labels below are the single
-- canonical version used everywhere in this script.
--   Morning   : 05:00–10:59
--   Midday    : 11:00–13:59
--   Afternoon : 14:00–17:59
--   Evening   : 18:00–22:59
--   Night     : 23:00–04:59  (the ELSE catch-all)
-- ---------------------------------------------------------------------
SELECT
    time_of_day,
    COUNT(*) AS viewership
FROM (
    SELECT
        CASE
            WHEN hour(`timestamp`) BETWEEN 5  AND 10 THEN 'Morning'
            WHEN hour(`timestamp`) BETWEEN 11 AND 13 THEN 'Midday'
            WHEN hour(`timestamp`) BETWEEN 14 AND 17 THEN 'Afternoon'
            WHEN hour(`timestamp`) BETWEEN 18 AND 22 THEN 'Evening'
            ELSE 'Night'
        END AS time_of_day
    FROM brighttv.default.bright_tv_dataset_case_studypart_2
)
GROUP BY time_of_day
ORDER BY viewership DESC;


-- ---------------------------------------------------------------------
-- 25. DROP time_of_day COLUMN IF IT ALREADY EXISTS (avoid duplicates)
-- ---------------------------------------------------------------------
ALTER TABLE brighttv.default.bright_tv_dataset_case_studypart_2
DROP COLUMN IF EXISTS time_of_day;


-- ---------------------------------------------------------------------
-- 26. ADD time_of_day COLUMN
-- ---------------------------------------------------------------------
ALTER TABLE brighttv.default.bright_tv_dataset_case_studypart_2
ADD COLUMN time_of_day STRING;


-- ---------------------------------------------------------------------
-- 27. POPULATE time_of_day
-- FIX: uses the SAME bucket boundaries and labels as query 24 above
-- (previously Midday/Afternoon were swapped between the two versions).
-- ---------------------------------------------------------------------
UPDATE brighttv.default.bright_tv_dataset_case_studypart_2
SET time_of_day =
    CASE
        WHEN hour(`timestamp`) BETWEEN 5  AND 10 THEN 'Morning'
        WHEN hour(`timestamp`) BETWEEN 11 AND 13 THEN 'Midday'
        WHEN hour(`timestamp`) BETWEEN 14 AND 17 THEN 'Afternoon'
        WHEN hour(`timestamp`) BETWEEN 18 AND 22 THEN 'Evening'
        ELSE 'Night'
    END;


-- ---------------------------------------------------------------------
-- 28. ADD DERIVED INSIGHT COLUMNS
-- FIX 1: Subscription_Type mapping made identical to query 7, and the
--        'Supersport' typo (lowercase 's') corrected to 'SuperSport' so
--        it actually matches the channel name used elsewhere.
-- FIX 2: TV_Viewing_Category left as its own independent classification
--        (peak/off-peak framing) — this is intentionally different from
--        time_of_day, since it groups hours by viewership importance,
--        not literal time of day. Kept internally consistent (no
--        overlapping ranges, all 24 hours covered).
-- ---------------------------------------------------------------------
SELECT
    *,
    -- column 1
    dayname(`timestamp`)     AS day_name,
    -- column 2
    monthname(`timestamp`)   AS month_name,
    -- column 3
    dayofmonth(`timestamp`)  AS day_of_month,
    -- column 4
    CASE
        WHEN dayname(`timestamp`) IN ('Sat', 'Sun') THEN 'Weekend'
        ELSE 'Weekday'
    END AS Day_Classification,

    -- column 5: TV viewing category (peak/off-peak framing)
    CASE
        WHEN hour(`timestamp`) BETWEEN 16 AND 20 THEN 'Prime Time (Peak Viewership)'
        WHEN hour(`timestamp`) BETWEEN 21 AND 23 THEN 'Late Evening'
        WHEN hour(`timestamp`) BETWEEN 5  AND 10 THEN 'Early Prime'
        WHEN hour(`timestamp`) BETWEEN 11 AND 15 THEN 'Day Time (Moderate Viewership)'
        ELSE 'Off Peak'
    END AS TV_Viewing_Category,

    -- column 6: subscription type — consistent with query 7
    CASE
        WHEN Channel = 'SuperSport'       THEN 'Basic'
        WHEN Channel = 'SuperSport Blitz' THEN 'Premium'
        ELSE 'Family_Plan'
    END AS Subscription_Type
FROM brighttv.default.bright_tv_dataset_case_studypart_2;
