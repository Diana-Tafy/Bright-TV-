SELECT
    UP.*, 
    V.Channel,
    V.sa_timestamp,
    
    -- FIX: This handles the NULLs created by the JOIN for users who didn't watch anything
    COALESCE(V.Duration_Seconds, 0) AS Duration_Seconds, 

    -- Column 1: Day Name
    DAYNAME(V.sa_timestamp) AS day_name,
    
    -- Column 2: Month Name
    MONTHNAME(V.sa_timestamp) AS month_name,
    
    -- Column 3: Day of Month
    DAYOFMONTH(V.sa_timestamp) AS day_of_month,
    
    -- Column 4: Weekend/Weekday
    CASE
        WHEN DAYNAME(V.sa_timestamp) IN ('Sat', 'Sun') THEN 'Weekend'
        ELSE 'Weekday'
    END AS Day_Classification,

    -- Column 5: TV Viewing Category
    CASE
        WHEN HOUR(V.sa_timestamp) BETWEEN 0 AND 6 THEN 'Early Morning'
        WHEN HOUR(V.sa_timestamp) BETWEEN 6 AND 10 THEN 'Early Birds'
        WHEN HOUR(V.sa_timestamp) BETWEEN 10 AND  16 THEN 'The Home Stayers'
        WHEN HOUR(V.sa_timestamp) BETWEEN 16 AND 18 THEN 'Prime Access'
        WHEN HOUR(V.sa_timestamp) BETWEEN 18 AND 20 THEN 'Prime Time(Peak Viewship)'
        WHEN HOUR(V.sa_timestamp) BETWEEN 21 AND 23 THEN 'Late Fringe'
        ELSE 'Off Peak'
    END AS TV_Viewing_Category,

    -- Column 6: Subscription Type
    CASE
        WHEN V.Channel IN ('Supersport', 'ICC Cricket World Cup 2011', 'Cartoon Network', 'E!Entertainment') THEN 'Premium'
        WHEN V.Channel IN ('Channel O', 'Trace TV', 'SuperSport Blitz') THEN 'Basic'
        ELSE 'Family_Plan'
    END AS Subscription_Type,

    -- Column 7: Age Group (Using UP.Age from the profile table)
    CASE
        WHEN UP.Age BETWEEN 18 AND 24 THEN 'Youth'
        WHEN UP.Age BETWEEN 25 AND 34 THEN 'Young Adults'
        WHEN UP.Age BETWEEN 35 AND 44 THEN 'Adults'
        WHEN UP.Age BETWEEN 45 AND 54 THEN 'Middle Aged'
        WHEN UP.Age BETWEEN 55 AND 64 THEN 'Seniors'
        ELSE 'Kids'
    END AS Age_Group,

    -- Column 8: Subscription Status
    CASE
        WHEN V.UserID_PRIMARY IS NULL THEN 'No Subscription'
        ELSE 'Subscribed'
    END AS Subscription_Status,

    --Column 9: Time of Day
    CASE 
        WHEN HOUR(V.sa_timestamp) BETWEEN 0 AND 4 THEN 'Early Birds'
        WHEN HOUR(V.sa_timestamp) BETWEEN 5 AND 10 THEN 'Daytime Browsers'
        WHEN HOUR(V.sa_timestamp) BETWEEN 11 AND 15 THEN 'Prime Timers'
        WHEN HOUR(V.sa_timestamp) BETWEEN 16 AND 21 THEN 'Late Night Viewers'
        ELSE 'Night Owls'
    END AS Viewer_Segment,

    -- Column 10: Estimated Revenue (Assumed Pricing)
    CASE 
        WHEN V.Channel IN ('Supersport', 'ICC Cricket World Cup 2011', 'Cartoon Network', 'E!Entertainment') THEN 150 -- Premium Price
        WHEN V.Channel IN ('Channel O', 'Trace TV', 'SuperSport Blitz') THEN 50 -- Basic Price
        WHEN V.UserID_PRIMARY IS NULL THEN 0 -- No Revenue
        ELSE 80 -- Family Plan Price
    END AS Estimated_Revenue
FROM brighttv.default.user_profile_btv AS UP
LEFT JOIN brighttv.default.viewership_btv AS V
    ON UP.UserID = V.UserID_Primary
ORDER BY UP.UserID ASC;
