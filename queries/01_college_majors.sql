-- Dataset 1: college majors (recent_grads and grad_students)
-- Article: "The Economic Guide To Picking A College Major" (FiveThirtyEight, 2014)
-- One row per major. Earnings are for recent graduates under 28 with a job.

-- 1.1 What does a row look like, and is anything missing?
SELECT COUNT(*) AS majors,
       SUM(total IS NULL) AS missing_total,
       SUM(share_women IS NULL) AS missing_share_women
FROM recent_grads;

-- 1.2 Recreate the article's ranking: highest and lowest paid majors.
SELECT rank, major, median, ROUND(share_women * 100, 1) AS pct_women
FROM recent_grads ORDER BY median DESC LIMIT 5;

SELECT rank, major, median, ROUND(share_women * 100, 1) AS pct_women
FROM recent_grads ORDER BY median ASC LIMIT 5;

-- 1.3 Earnings by category. A plain AVG(median) treats a major with 600 grads the same as one
--     with 300,000, so this weights each major by how many graduates it has.
SELECT major_category,
       COUNT(*) AS majors,
       SUM(total) AS graduates,
       ROUND(SUM(1.0 * median * total) / SUM(total)) AS weighted_median,
       ROUND(AVG(median)) AS plain_avg_median,
       ROUND(100.0 * SUM(women) / SUM(total), 1) AS pct_women
FROM recent_grads
WHERE total IS NOT NULL
GROUP BY major_category
ORDER BY weighted_median DESC;

-- 1.4 The article says majors with more women tend to pay less. Check it by grouping majors
--     into four bands by share of women.
SELECT CASE WHEN share_women < 0.25 THEN '1. under 25% women'
            WHEN share_women < 0.50 THEN '2. 25 to 50%'
            WHEN share_women < 0.75 THEN '3. 50 to 75%'
            ELSE '4. 75% or more' END AS band,
       COUNT(*) AS majors,
       ROUND(AVG(median)) AS avg_median,
       MIN(median) AS lowest,
       MAX(median) AS highest
FROM recent_grads
WHERE share_women IS NOT NULL
GROUP BY band
ORDER BY band;

-- 1.5 Is that just engineering? Same check with engineering taken out.
SELECT CASE WHEN share_women < 0.50 THEN 'under 50% women' ELSE '50% or more' END AS band,
       COUNT(*) AS majors,
       ROUND(AVG(median)) AS avg_median
FROM recent_grads
WHERE share_women IS NOT NULL AND major_category <> 'Engineering'
GROUP BY band;

-- 1.6 My own question: pay is not the only thing. Which big majors have the worst unemployment,
--     and how many of their employed grads are in jobs that do not need a degree?
SELECT major, total,
       ROUND(unemployment_rate * 100, 1) AS unemployment_pct,
       ROUND(100.0 * non_college_jobs / (college_jobs + non_college_jobs), 1) AS pct_in_non_college_jobs,
       median
FROM recent_grads
WHERE total > 50000
ORDER BY unemployment_rate DESC
LIMIT 8;

-- 1.7 Across all majors: how many employed recent grads are in jobs that do not need a degree?
SELECT ROUND(100.0 * SUM(non_college_jobs) / SUM(college_jobs + non_college_jobs), 1) AS pct_non_college_jobs,
       ROUND(100.0 * SUM(low_wage_jobs) / SUM(employed), 1) AS pct_low_wage_jobs
FROM recent_grads;

-- 1.8 Combining two files (extension): does a graduate degree pay off the same in every field?
--     grad_students has the earnings of people with a graduate degree, by undergrad major.
--     grad_premium = how much more grad-degree holders earn than people who stopped at a bachelor's.
SELECT r.major_category,
       COUNT(*) AS majors,
       ROUND(AVG(g.grad_premium) * 100, 1) AS avg_grad_premium_pct,
       ROUND(AVG(g.grad_share) * 100, 1) AS pct_who_get_grad_degree,
       ROUND(AVG(r.median)) AS avg_recent_grad_median
FROM recent_grads AS r
JOIN grad_students AS g ON g.major_code = r.major_code
GROUP BY r.major_category
ORDER BY avg_grad_premium_pct DESC;

-- 1.9 The majors where a graduate degree changes the most and the least.
SELECT r.major, r.median AS recent_grad_median, g.nongrad_median, g.grad_median,
       ROUND(g.grad_premium * 100) AS grad_premium_pct
FROM recent_grads AS r
JOIN grad_students AS g ON g.major_code = r.major_code
ORDER BY g.grad_premium DESC LIMIT 5;

SELECT r.major, r.median AS recent_grad_median, g.nongrad_median, g.grad_median,
       ROUND(g.grad_premium * 100) AS grad_premium_pct
FROM recent_grads AS r
JOIN grad_students AS g ON g.major_code = r.major_code
ORDER BY g.grad_premium ASC LIMIT 5;
