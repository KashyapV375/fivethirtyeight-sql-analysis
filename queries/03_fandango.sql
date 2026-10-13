-- Dataset 3: Fandango movie ratings (fandango_all and fandango_compare)
-- Article: "Be Suspicious Of Online Movie Ratings, Especially Fandango's" (FiveThirtyEight, 2015)
-- fandango_all     = every film pulled from Fandango (stars shown on the site, and the real average)
-- fandango_compare = films that also have Rotten Tomatoes, Metacritic and IMDb scores,
--                    with every score converted to a 0 to 5 scale

-- 3.1 How many films, and how many have enough reviews to mean anything?
SELECT COUNT(*) AS films,
       SUM(votes >= 1)  AS with_at_least_1_review,
       SUM(votes >= 30) AS with_30_or_more
FROM fandango_all;

-- 3.2 The article's headline: almost nothing on Fandango is rated badly.
SELECT COUNT(*) AS films,
       ROUND(100.0 * SUM(stars >= 3) / COUNT(*), 1) AS pct_3_stars_or_more,
       ROUND(100.0 * SUM(stars >= 4) / COUNT(*), 1) AS pct_4_stars_or_more,
       SUM(stars < 2) AS films_under_2_stars
FROM fandango_all
WHERE votes >= 1;

-- 3.3 The full spread of stars.
SELECT stars, COUNT(*) AS films,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM fandango_all WHERE votes >= 1), 1) AS pct
FROM fandango_all
WHERE votes >= 1
GROUP BY stars
ORDER BY stars DESC;

-- 3.4 The rounding problem. "rating" is the real average, "stars" is what the site displayed.
--     Normal rounding to the nearest half star would give differences between -0.2 and +0.2.
SELECT ROUND(stars - rating, 1) AS stars_minus_real_rating, COUNT(*) AS films
FROM fandango_all
WHERE votes >= 1
GROUP BY stars_minus_real_rating
ORDER BY stars_minus_real_rating;

-- 3.5 Did the displayed stars ever round DOWN?
SELECT SUM(stars < rating) AS rounded_down,
       SUM(stars = rating) AS shown_exactly,
       SUM(stars > rating) AS rounded_up,
       ROUND(100.0 * SUM(stars - rating >= 0.3) / COUNT(*), 1) AS pct_pushed_up_past_normal_rounding
FROM fandango_all
WHERE votes >= 1;

-- 3.6 The film that got a whole extra star.
SELECT film, rating AS real_rating, stars AS stars_shown, votes
FROM fandango_all
WHERE stars - rating >= 0.9;

-- 3.7 Fandango against the other sites, same 146 films, everything on a 0 to 5 scale.
SELECT COUNT(*) AS films,
       ROUND(AVG(fandango_stars), 2)     AS fandango_stars,
       ROUND(AVG(fandango_rating), 2)    AS fandango_real_avg,
       ROUND(AVG(imdb_5), 2)             AS imdb,
       ROUND(AVG(metacritic_users_5), 2) AS metacritic_users,
       ROUND(AVG(rt_users_5), 2)         AS rt_users,
       ROUND(AVG(rt_critics_5), 2)       AS rt_critics,
       ROUND(AVG(metacritic_5), 2)       AS metacritic_critics
FROM fandango_compare;

-- 3.8 For how many films is Fandango the single highest score of all six?
SELECT SUM(fandango_stars > rt_critics_5 AND fandango_stars > rt_users_5 AND fandango_stars > metacritic_5
           AND fandango_stars > metacritic_users_5 AND fandango_stars > imdb_5) AS fandango_is_highest,
       COUNT(*) AS films
FROM fandango_compare;

-- 3.9 How many films does each site call "good" (4 out of 5 or better)?
SELECT SUM(fandango_stars >= 4)     AS fandango,
       SUM(rt_users_5 >= 4)         AS rt_users,
       SUM(rt_critics_5 >= 4)       AS rt_critics,
       SUM(metacritic_users_5 >= 4) AS metacritic_users,
       SUM(imdb_5 >= 4)             AS imdb
FROM fandango_compare;

-- 3.10 My own question: which films have the biggest gap between Fandango and the critics?
SELECT film, fandango_stars, rt_critics_5 AS rt_critics, ROUND(fandango_stars - rt_critics_5, 1) AS gap
FROM fandango_compare
ORDER BY gap DESC
LIMIT 6;

-- 3.11 Is there any film where Fandango is the LOWEST of the six?
SELECT COUNT(*) AS fandango_is_lowest
FROM fandango_compare
WHERE fandango_stars < rt_critics_5 AND fandango_stars < rt_users_5 AND fandango_stars < metacritic_5
  AND fandango_stars < metacritic_users_5 AND fandango_stars < imdb_5;

-- 3.12 Does more reviews mean a more honest score? Average stars by how many people voted.
SELECT CASE WHEN votes < 30 THEN '1. under 30 votes'
            WHEN votes < 1000 THEN '2. 30 to 999'
            WHEN votes < 10000 THEN '3. 1,000 to 9,999'
            ELSE '4. 10,000 or more' END AS vote_band,
       COUNT(*) AS films,
       ROUND(AVG(stars), 2) AS avg_stars_shown,
       ROUND(AVG(rating), 2) AS avg_real_rating,
       MIN(stars) AS lowest_stars
FROM fandango_all
WHERE votes >= 1
GROUP BY vote_band
ORDER BY vote_band;
