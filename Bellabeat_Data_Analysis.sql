
# Checking Columns Across Tables

-- Check to see which column names are shared across tables
SELECT
    column_name,
    COUNT(table_name) AS table_count
FROM
    INFORMATION_SCHEMA.COLUMNS
WHERE
    TABLE_SCHEMA = 'fitness_tracker'
GROUP BY
    column_name;

-- Ensure every table has an "Id" column
SELECT
    table_name,
    SUM(CASE WHEN column_name = 'Id' THEN 1 ELSE 0 END) AS has_id_column
FROM
    INFORMATION_SCHEMA.COLUMNS
WHERE
    TABLE_SCHEMA = 'fitness_tracker'
GROUP BY
    table_name
ORDER BY
    table_name ASC;


-- Check for columns of a date or time-related type
SELECT
    table_name
FROM
    INFORMATION_SCHEMA.COLUMNS
WHERE
    TABLE_SCHEMA = 'fitness_tracker'
    AND UPPER(data_type) IN ('TIMESTAMP', 'DATETIME', 'TIME', 'DATE')
GROUP BY
    table_name;



-- Identify date or time-related columns
SELECT
    CONCAT(table_schema, '.', table_name) AS table_path,
    table_name,
    column_name
FROM
    INFORMATION_SCHEMA.COLUMNS
WHERE
    TABLE_SCHEMA = 'fitness_tracker'
    AND UPPER(data_type) IN ('TIMESTAMP', 'DATETIME', 'DATE');



-- Check for columns with potential date-related keywords
SELECT
    table_name,
    column_name
FROM
    INFORMATION_SCHEMA.COLUMNS
WHERE
    TABLE_SCHEMA = 'fitness_tracker'
    AND LOWER(column_name) REGEXP 'date|minute|daily|hourly|day|seconds';



-- Validate timestamp format in daily_activity table
SELECT
    ActivityDate,
    ActivityDate REGEXP '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$' AS is_timestamp
FROM
    fitness_tracker.dailyactivities
LIMIT 5;


-- Validate if all ActivityDate columns follow the timestamp pattern
SELECT
    CASE
        WHEN SUM(ActivityDate REGEXP '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$') = COUNT(*) THEN "Valid"
        ELSE "Not Valid"
    END AS valid_test
FROM
    fitness_tracker.dailyactivities;


-- Identify tables with daily data
SELECT DISTINCT table_name
FROM INFORMATION_SCHEMA.COLUMNS
WHERE LOWER(table_name) LIKE '%day%' OR LOWER(table_name) LIKE '%daily%';


-- Identify columns shared among daily tables
SELECT 
    column_name,
    data_type,
    COUNT(table_name) AS table_count
FROM 
    INFORMATION_SCHEMA.COLUMNS
WHERE 
    LOWER(table_name) LIKE '%day%' OR LOWER(table_name) LIKE '%daily%'
GROUP BY 
    column_name,
    data_type;


-- Ensure data types align between tables
SELECT
    c.column_name,
    c.table_name,
    c.data_type
FROM
    INFORMATION_SCHEMA.COLUMNS c
JOIN (
    SELECT
        column_name
    FROM
        INFORMATION_SCHEMA.COLUMNS
    WHERE
        LOWER(table_name) LIKE '%day%' OR LOWER(table_name) LIKE '%daily%'
    GROUP BY
        column_name
    HAVING
        COUNT(DISTINCT table_name) >= 2
) AS sub ON c.column_name = sub.column_name
WHERE
    LOWER(c.table_name) LIKE '%day%' OR LOWER(c.table_name) LIKE '%daily%'
ORDER BY
    c.column_name;

##           ***               ##              ***             ##           ***            ##             **           ##         **

-- Join tables on shared columns
SELECT
    A.Id,
    A.Calories,
    A.TotalSteps,
    A.TotalDistance,
    A.TrackerDistance,
    A.LoggedActivitiesDistance,
    A.VeryActiveDistance,
    A.ModeratelyActiveDistance,
    A.LightActiveDistance,
    A.SedentaryActiveDistance,
    A.VeryActiveMinutes,
    A.FairlyActiveMinutes,
    A.LightlyActiveMinutes,
    A.SedentaryMinutes,
    C.Calories AS DailyCalories,
    I.FairlyActiveMinutes AS DailyFairlyActiveMinutes,
    I.LightActiveDistance AS DailyLightActiveDistance,
    I.LightlyActiveMinutes AS DailyLightlyActiveMinutes,
    I.ModeratelyActiveDistance AS DailyModeratelyActiveDistance,
    I.SedentaryActiveDistance AS DailySedentaryActiveDistance,
    I.SedentaryMinutes AS DailySedentaryMinutes,
    I.VeryActiveDistance AS DailyVeryActiveDistance,
    I.VeryActiveMinutes AS DailyVeryActiveMinutes,
    S.StepTotal AS DailyTotalSteps,
    Sl.TotalMinutesAsleep AS TotalMinutesAsleep,
    Sl.TotalTimeInBed AS TotalTimeInBed
FROM
    fitness_tracker.dailyactivities A
LEFT JOIN
    fitness_tracker.dailycalories_merged C
ON
    A.Id = C.Id
    AND A.ActivityDate = C.ActivityDate
LEFT JOIN
    fitness_tracker.dailyintensities_merged I
ON
    A.Id = I.Id
    AND A.ActivityDate = I.ActivityDate
    
LEFT JOIN
    fitness_tracker.dailysteps_merged S
ON
    A.Id = S.Id
    AND A.ActivityDate = S.ActivityDate
LEFT JOIN
    fitness_tracker.sleepday Sl
ON
    A.Id = Sl.Id
    AND A.ActivityDate = Sl.SleepDay;


# Analysis Based on Time of Day and Day of the Week
-- Suppose we would like to do an analysis based upon the time of day and day of the week
-- We will do this at a person level such that we smooth over anomalous days for an individual
WITH user_dow_summary AS (
    SELECT
        Id,
        DAYOFWEEK(ActivityDate) AS dow_number,
        DATE_FORMAT(ActivityDate, '%W') AS day_of_week,
        AVG(Calories) AS avg_calories,
        AVG(TotalSteps) AS avg_steps,
        AVG(TotalDistance) AS avg_distance,
        AVG(VeryActiveMinutes) AS avg_very_active_minutes,
        AVG(FairlyActiveMinutes) AS avg_fairly_active_minutes,
        AVG(LightlyActiveMinutes) AS avg_lightly_active_minutes,
        AVG(SedentaryMinutes) AS avg_sedentary_minutes
    FROM
        fitness_tracker.dailyactivities
    GROUP BY
        Id,
        dow_number,
        day_of_week
)
SELECT
    dow_number,
    day_of_week,
    AVG(avg_calories) AS avg_calories,
    AVG(avg_steps) AS avg_steps,
    AVG(avg_distance) AS avg_distance,
    AVG(avg_very_active_minutes) AS avg_very_active_minutes,
    AVG(avg_fairly_active_minutes) AS avg_fairly_active_minutes,
    AVG(avg_lightly_active_minutes) AS avg_lightly_active_minutes,
    AVG(avg_sedentary_minutes) AS avg_sedentary_minutes
FROM
    user_dow_summary
GROUP BY
    dow_number,
    day_of_week
ORDER BY
    dow_number;

-- Say we are considering sleep related products as a possibility, let's take a
-- moment to see if/ how people nap during the day--To do this we are assuming that a nap is any time someone sleeps but goes to sleep
-- and wakes up on the same day
-- Assuming sleep related products and analyzing nap patterns
-- A nap is any time someone sleeps and wakes up on the same day
SELECT
    Id,
    sleep_date,
    Count(logId) AS number_naps,
    SEC_TO_TIME(SUM(sleep_duration_in_seconds)) AS total_sleep_duration
FROM (
    SELECT
        Id,
        DATE(Date) AS sleep_date,
        logId,
        TIME_TO_SEC(TIMEDIFF(MAX(TIMESTAMP(CONCAT(Date, ' ', ActivityHour))), MIN(TIMESTAMP(CONCAT(Date, ' ', ActivityHour))))) AS sleep_duration_in_seconds
    FROM
        `minutesleep_merged`
    WHERE
        value = 1 -- Assuming value 1 indicates sleep
    GROUP BY
        Id,
        logId,
        DATE(Date)
) AS subquery
GROUP BY
    Id,
    sleep_date,
    logId;


# Joining all hourly activities 

SELECT 
    ha.Id,
    ha.ActivityHour,
    ha.StepTotal,
    ha.Calories,
    ha.TotalIntensity,
    ha.AverageIntensity,
    hc.Date,
    hc.Calories AS hc_Calories,
    hi.TotalIntensity AS hi_TotalIntensity,
    hi.AverageIntensity AS hi_AverageIntensity,
    hs.StepTotal AS hs_StepTotal
FROM 
    hourlyactivities ha
LEFT JOIN 
    hourlyCalories_merged hc ON ha.Id = hc.Id AND ha.ActivityHour = hc.Date
LEFT JOIN 
    hourlyIntensities_merged hi ON ha.Id = hi.Id AND ha.ActivityHour = hi.Date
LEFT JOIN 
    hourlySteps_merged hs ON ha.Id = hs.Id AND ha.ActivityHour = hs.Date;



# Statistics summary of heart beat
select
Id,
count(Id),
Avg(Heart_beat) As Avrege_Heart_Beat,
max(Heart_beat) As MaX_Heart_Beat,
min(heart_beat) As Min_Heart_Beat
From fitness_tracker.heart_beat
group by id
limit 1000;

# finding maximum heart_beat by unique id with time
with RankedHeartRates As (
              select id, time, heart_beat,
              row_number() over (partition by id order by heart_beat desc) As rn
 From fitness_tracker.heart_beat)
 select id, time, heart_beat As Max_Heart_Beat
 from RankedHeartRates
 where rn = 1 
 limit 100;
# finding minmum heart_beat by unique id With Time

with RankedHeartRates As (
              select id, time, heart_beat,
              row_number() over (partition by id order by heart_beat ) As rn
 From fitness_tracker.heart_beat)
 select id, time, heart_beat As Min_Heart_Beat
 from RankedHeartRates
 where rn = 1 
 limit 100;
 
 # Daily Activity Analysis
 SELECT 
id,
count(id) As Numbers_Count,
Avg(TotalDistance) As AverageTotal_Distance,
max(TotalDistance) As MaxmumTotal_Distance,
min(TotalDistance) As MinmumTotal_Distance
 FROM fitness_tracker.dailyactivities
 group by Id;
 
 select distinct(ActivityDate),
 id,
 TotalDistance

from fitness_tracker.dailyactivities
where TotalDistance = (select max(TotalDistance) From fitness_tracker.dailyactivities)  or
       TotalDistance = (select min(TotalDistance) From fitness_tracker.dailyactivities);
 


