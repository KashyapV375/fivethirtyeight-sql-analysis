-- Dataset 2: the Bechdel test (bechdel)
-- Article: "The Dollar-And-Cents Case Against Hollywood's Exclusion of Women" (FiveThirtyEight, 2014)
-- A movie passes if it has two named women who talk to each other about something other than a man.
-- Dollar columns ending in _2013 are adjusted for inflation.

-- 2.1 How many films, what years, and how much is missing?
SELECT COUNT(*) AS films, MIN(year) AS first_year, MAX(year) AS last_year,
       SUM(domgross_2013 IS NULL) AS missing_domestic,
       SUM(intgross_2013 IS NULL) AS missing_international
FROM bechdel;

-- 2.2 The article analyzes 1990 to 2013. How many films is that, and how many pass?
SELECT COUNT(*) AS films,
       SUM(result = 'PASS') AS passed,
       ROUND(100.0 * SUM(result = 'PASS') / COUNT(*), 1) AS pass_pct
FROM bechdel
WHERE year BETWEEN 1990 AND 2013;

-- 2.3 Why do films fail?
SELECT clean_test,
       CASE clean_test WHEN 'ok' THEN 'passes'
                       WHEN 'notalk' THEN 'two women, but they never talk to each other'
                       WHEN 'men' THEN 'they only talk about a man'
                       WHEN 'nowomen' THEN 'fewer than two women'
                       WHEN 'dubious' THEN 'disputed' END AS meaning,
       COUNT(*) AS films,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM bechdel), 1) AS pct
FROM bechdel
GROUP BY clean_test
ORDER BY films DESC;

-- 2.4 Has it gotten better over time?
SELECT (year / 10) * 10 AS decade,
       COUNT(*) AS films,
       ROUND(100.0 * SUM(result = 'PASS') / COUNT(*), 1) AS pass_pct
FROM bechdel
GROUP BY decade
ORDER BY decade;

-- 2.5 Budgets. SQLite has no MEDIAN(), so this numbers the rows inside each group and takes the
--     middle one (or the average of the middle two).
WITH ranked AS (
    SELECT result, budget_2013,
           ROW_NUMBER() OVER (PARTITION BY result ORDER BY budget_2013) AS position,
           COUNT(*)     OVER (PARTITION BY result) AS group_size
    FROM bechdel
    WHERE year BETWEEN 1990 AND 2013
)
SELECT result, group_size AS films, ROUND(AVG(budget_2013)) AS median_budget_2013
FROM ranked
WHERE position IN ((group_size + 1) / 2, (group_size + 2) / 2)
GROUP BY result;

-- 2.6 The article's main number: return on investment, worldwide gross per dollar of budget.
WITH ranked AS (
    SELECT result, 1.0 * intgross_2013 / budget_2013 AS roi,
           ROW_NUMBER() OVER (PARTITION BY result ORDER BY 1.0 * intgross_2013 / budget_2013) AS position,
           COUNT(*)     OVER (PARTITION BY result) AS group_size
    FROM bechdel
    WHERE year BETWEEN 1990 AND 2013 AND intgross_2013 IS NOT NULL
)
SELECT result, group_size AS films, ROUND(AVG(roi), 2) AS median_worldwide_gross_per_dollar
FROM ranked
WHERE position IN ((group_size + 1) / 2, (group_size + 2) / 2)
GROUP BY result;

-- 2.7 Same thing for US gross only.
WITH ranked AS (
    SELECT result, 1.0 * domgross_2013 / budget_2013 AS roi,
           ROW_NUMBER() OVER (PARTITION BY result ORDER BY 1.0 * domgross_2013 / budget_2013) AS position,
           COUNT(*)     OVER (PARTITION BY result) AS group_size
    FROM bechdel
    WHERE year BETWEEN 1990 AND 2013 AND domgross_2013 IS NOT NULL
)
SELECT result, group_size AS films, ROUND(AVG(roi), 2) AS median_us_gross_per_dollar
FROM ranked
WHERE position IN ((group_size + 1) / 2, (group_size + 2) / 2)
GROUP BY result;

-- 2.8 My own check: is the ROI gap just because passing films are cheaper, and cheap films
--     have higher ROI no matter what? Compare pass and fail inside the same budget band.
SELECT CASE WHEN budget_2013 < 20000000 THEN '1. under $20M'
            WHEN budget_2013 < 60000000 THEN '2. $20M to $60M'
            WHEN budget_2013 < 120000000 THEN '3. $60M to $120M'
            ELSE '4. over $120M' END AS budget_band,
       result,
       COUNT(*) AS films,
       ROUND(1.0 * SUM(intgross_2013) / SUM(budget_2013), 2) AS total_gross_per_dollar
FROM bechdel
WHERE year BETWEEN 1990 AND 2013 AND intgross_2013 IS NOT NULL
GROUP BY budget_band, result
ORDER BY budget_band, result;

-- 2.9 How much of the big-budget money goes to films that pass?
SELECT CASE WHEN budget_2013 >= 120000000 THEN 'over $120M' ELSE 'under $120M' END AS budget_band,
       COUNT(*) AS films,
       ROUND(100.0 * SUM(result = 'PASS') / COUNT(*), 1) AS pass_pct
FROM bechdel
WHERE year BETWEEN 1990 AND 2013
GROUP BY budget_band;
