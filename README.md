# Introduction
Welcome to the Bellabeat data analysis case study! In this case study, I will perform many real-world tasks of a junior data analyst. I will imagine I am working for Bellabeat, a high-tech manufacturer of health-focused products for women, and meet different characters and team members. In order to answer the key business questions, I will follow the steps of the data analysis process: ask, prepare, process, analyze, share, and act. Along the way, the Case Study Roadmap tables — including guiding questions and key tasks — will help me stay on the right path.

# Scenario
I am a junior data analyst working on the marketing analyst team at Bellabeat. Bellabeat is a successful small company with the potential to become a larger player in the global smart device market. Urška Sršen, cofounder and Chief Creative Officer of Bellabeat, believes that analyzing smart device fitness data could help unlock new growth opportunities for the company. I have been asked to focus on one of Bellabeat’s products and analyze smart device data to gain insight into how consumers are using their smart devices. The insights I discover will then help guide marketing strategy for the company. I will present my analysis to the Bellabeat executive team along with my high-level recommendations for Bellabeat’s marketing strategy.

# Characters and Products

#### Characters
* Urška Sršen: Bellabeat’s cofounder and Chief Creative Officer
* Sando Mur: Mathematician and Bellabeat’s cofounder; key member of the Bellabeat executive team
* Bellabeat marketing analytics team: A team of data analysts responsible for collecting, analyzing, and reporting data that helps guide Bellabeat’s marketing strategy. I joined this team six months ago and have been busy learning about Bellabeat’s mission and business goals — as well as how you, as a junior data analyst, can help Bellabeat achieve them.

#### Products
* **Bellabeat app:** The Bellabeat app provides users with health data related to their activity, sleep, stress, menstrual cycle, and mindfulness habits. This data can help users better understand their current habits and make healthy decisions. The Bellabeat app connects to their line of smart wellness products.
* **Leaf:** Bellabeat’s classic wellness tracker can be worn as a bracelet, necklace, or clip. The Leaf tracker connects to the Bellabeat app to track activity, sleep, and stress.
* **Time:** This wellness watch combines the timeless look of a classic timepiece with smart technology to track user activity, sleep, and stress. The Time watch connects to the Bellabeat app to provide insights into daily wellness.
* **Spring:** This is a water bottle that tracks daily water intake using smart technology to ensure appropriate hydration throughout the day. The Spring bottle connects to the Bellabeat app to track hydration levels.
* **Bellabeat membership:** A subscription-based membership program offering personalized guidance on nutrition, activity, sleep, health and beauty, and mindfulness based on lifestyle and goals.

# Ask
Sršen asks me to analyze smart device usage data to gain insight into how consumers use non-Bellabeat smart devices. She then wants I to select one Bellabeat product to apply these insights to in my presentation. These questions will guide my analysis:

1. What are some trends in smart device usage?
2. How could these trends apply to Bellabeat customers?
3. How could these trends help influence Bellabeat marketing strategy?

# Prepare
Sršen encourages me to use public data that explores smart device users’ daily habits. She points me to a specific dataset:

FitBit Fitness Tracker Data (CC0: Public Domain, dataset made available through Mobius): This Kaggle dataset contains personal fitness tracker data from thirty Fitbit users. Thirty eligible Fitbit users consented to the submission of personal tracker data, including minute-level output for physical activity, heart rate, and sleep monitoring. It includes information about daily activity, steps, and heart rate that can be used to explore users’ habits.

Sršen tells me that this dataset might have some limitations and encourages me to consider adding another dataset to help address those limitations as you begin to work more with this data.

# Data Cleaning and Analysis Using SQL
Let's start with cleaning and analyzing the dataset using SQL. The following steps outline the process for each table:

* **Importing Data:** Load all tables into a SQL database.
* **Data Cleaning:** Perform necessary data cleaning tasks, including handling missing values, removing duplicates, and correcting data types.
* **Data Analysis:** Execute SQL queries to derive insights from the data.
___

# Checking Columns Across Tables

-- Check to see which column names are shared across tables
```sql
SELECT
    column_name,
    COUNT(table_name) AS table_count
FROM
    INFORMATION_SCHEMA.COLUMNS
WHERE
    TABLE_SCHEMA = 'fitness_tracker'
GROUP BY
    column_name;
```
-- Ensure every table has an "Id" column
```sql
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

```
-- Check for columns of a date or time-related type
```sql
SELECT
    table_name
FROM
    INFORMATION_SCHEMA.COLUMNS
WHERE
    TABLE_SCHEMA = 'fitness_tracker'
    AND UPPER(data_type) IN ('TIMESTAMP', 'DATETIME', 'TIME', 'DATE')
GROUP BY
    table_name;

```
-- Identify date or time-related columns
```sql
SELECT
    CONCAT(table_schema, '.', table_name) AS table_path,
    table_name,
    column_name
FROM
    INFORMATION_SCHEMA.COLUMNS
WHERE
    TABLE_SCHEMA = 'fitness_tracker'
    AND UPPER(data_type) IN ('TIMESTAMP', 'DATETIME', 'DATE');

```

-- Check for columns with potential date-related keywords
```sql
SELECT
    table_name,
    column_name
FROM
    INFORMATION_SCHEMA.COLUMNS
WHERE
    TABLE_SCHEMA = 'fitness_tracker'
    AND LOWER(column_name) REGEXP 'date|minute|daily|hourly|day|seconds';

```
-- Validate timestamp format in daily_activity table

```sql
SELECT
    ActivityDate,
    ActivityDate REGEXP '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$' AS is_timestamp
FROM
    fitness_tracker.dailyactivities
LIMIT 5;

```
-- Validate if all ActivityDate columns follow the timestamp pattern
```sql

SELECT
    CASE
        WHEN SUM(ActivityDate REGEXP '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$') = COUNT(*) THEN "Valid"
        ELSE "Not Valid"
    END AS valid_test
FROM
    fitness_tracker.dailyactivities;

```
-- Identify tables with daily data
```sql
SELECT DISTINCT table_name
FROM INFORMATION_SCHEMA.COLUMNS
WHERE LOWER(table_name) LIKE '%day%' OR LOWER(table_name) LIKE '%daily%';

```
-- Identify columns shared among daily tables
```sql
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

```
-- Ensure data types align between tables
```sql
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

```
-- Join tables on shared columns by days

```sql
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

```

-- Analysis Based on Time of Day and Day of the Week.\
-- Suppose we would like to do an analysis based upon the time of day and day of the week.\
-- We will do this at a person level such that we smooth over anomalous days for an individual.
```sql
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

```
--  we are considering sleep related products as a possibility, let's take amoment to see if how people nap during the day.To do this we are assuming that a nap is any time someone sleeps but goes to sleep and wakes up on the same day.\
-- Assuming sleep related products and analyzing nap patterns\
-- A nap is any time someone sleeps and wakes up on the same day

```sql

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

```
-- Joining all hourly activities Tables

```sql
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

```
-- Statistics summary of heart beat:
```sql
SELECT
    Id,
    count(Id),
    Avg(Heart_beat) AS Avrege_Heart_Beat,
    max(Heart_beat) AS MaX_Heart_Beat,
    min(heart_beat) AS Min_Heart_Beat
FROM fitness_tracker.heart_beat
GROUP BY id
LIMIT 1000;

```

-- Finding maximum heart_beat by unique id with time

```sql
WITH RankedHeartRates AS (
    SELECT id, time, heart_beat,
    row_number() OVER (PARTITION BY id ORDER BY heart_beat DESC) AS rn
    FROM fitness_tracker.heart_beat
)
SELECT id, time, heart_beat AS Max_Heart_Beat
FROM RankedHeartRates
WHERE rn = 1 
LIMIT 100;

```
-- Finding minimum heart_beat by unique id with time
```sql
WITH RankedHeartRates AS (
    SELECT id, time, heart_beat,
    row_number() OVER (PARTITION BY id ORDER BY heart_beat) AS rn
    FROM fitness_tracker.heart_beat
)
SELECT id, time, heart_beat AS Min_Heart_Beat
FROM RankedHeartRates
WHERE rn = 1 
LIMIT 100;

```

-- Daily Activity Analysis: Summary Statistics
```sql
SELECT 
    id,
    COUNT(id) AS Numbers_Count,
    AVG(TotalDistance) AS AverageTotal_Distance,
    MAX(TotalDistance) AS MaxmumTotal_Distance,
    MIN(TotalDistance) AS MinmumTotal_Distance
FROM fitness_tracker.dailyactivities
GROUP BY Id;
```
-- Daily Activity Analysis: Days with Maximum and Minimum Total Distance
```sql
SELECT DISTINCT(ActivityDate),
    id,
    TotalDistance
FROM fitness_tracker.dailyactivities
WHERE TotalDistance = (SELECT MAX(TotalDistance) FROM fitness_tracker.dailyactivities)  OR
       TotalDistance = (SELECT MIN(TotalDistance) FROM fitness_tracker.dailyactivities);

```
___

# Summary of Analysis
1. **Trends in Daily Activities:**
 • General activities of the user are as ■ spelled out by their average steps per day and average calories burned per user.
 • The trends of both active and sedentary minutes are responsible for spot the low and high periods of activity.
2. **Heart Rate Analysis:**
- The average heart rate a user has at different times of the day is built by the day and hour trends for the heart rate which in turn helps in getting to know cardiovascular health.
3. **Hourly Activity Trends:**
 The measurement of that parameter of energy incinerating every hour like calories, intensities, and steps contributed to the proper determination of the periods of peak activity throughout the day.
4. **Minute-Level Trends:**
 Analysing every minute of exercise gives us very detailed information on the one hand, but on the other, it is not convenient, because speeding up our performance in specific directions may develop only at text lists and in the best case they show the user's driving style examination.
5. **Sleep Patterns:**
 As for the sleep, the data like Average minutes asleep, minutes awake, number of awakenings, and sleep efficiency are all counted in.
___
# Conclusions and Recommendations

1. **Trends in Smart Device Usage:**
   - Each of course has its own distinct daily patterns that users exhibit, with peaks in activity usually around morning and night.
   - For example, how the detailed heart rate data varies over a 24 hour period can be an important point for cardiovascular activity.
   - After analyzing the data we have got sleep pattern of bellabeat users by using thes we can improve the sleep quality and duration of bellabeat users.

2. **Application to Bellabeat Customers:**
   -This data can then be used by Bellabeat to pitch its own personalised health recommendations inside the app.
   - Bellabeat can create specific marketing campaigns based on peak activity times for products like Leaf, Time and Spring.

3. **Recommendations for Marketing Strategy:**
   - Custom Notification: By customizing the notification of the app we can encourage bellabeat users to stay active during at low-activity period.
   - Continuous Sleep Improvement Programs - Create content utilizing sleep quality and data to drive engagement around programs aimed towards helping users optimize their sleep Live Data Tracking.
   - Targeted Advertising:The marketing campaigns should be run during the perio when the users are mostely active to increase their engagement.
___
By following these strategies, Bellabeat can enhance user engagement, improve product adoption, and ultimately drive growth.
___
