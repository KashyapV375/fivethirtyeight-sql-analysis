# What three FiveThirtyEight datasets say, in SQL

FiveThirtyEight publishes the data behind its articles. This project loads three of those datasets into a database, recreates the main numbers from each article with SQL, and then asks a few questions the articles did not.

| # | Dataset | Article | Tables |
|---|---|---|---|
| 1 | College majors | The Economic Guide To Picking A College Major (2014) | `recent_grads`, `grad_students` |
| 2 | Bechdel test | The Dollar-And-Cents Case Against Hollywood's Exclusion of Women (2014) | `bechdel` |
| 3 | Fandango ratings | Be Suspicious Of Online Movie Ratings, Especially Fandango's (2015) | `fandango_all`, `fandango_compare` |

The CSV files in `data/` are unchanged copies from [github.com/fivethirtyeight/data](https://github.com/fivethirtyeight/data).

## A note on the database

The project directions use SQL Server and SSMS. I do not have SQL Server (it does not run on a Mac without Docker), so this is built on **SQLite**. `load_data.py` does the job that `BULK INSERT` would do: it reads each CSV, creates a table with real column types, and inserts the rows. The queries are plain SQL. The two things that would need changing for SQL Server are `LIMIT 5` (which is `TOP 5` there) and the `SUM(condition)` counting trick (which would be `SUM(CASE WHEN condition THEN 1 ELSE 0 END)`). I have not run them on SQL Server.

## Running it

```
python load_data.py      # builds fivethirtyeight.db from the CSVs
sh run_queries.sh        # runs every file in queries/ and saves the output in results/
```

Needs Python 3 and the `sqlite3` command line tool. No packages to install.

## Did my numbers match the articles?

| Article says | My query | Match? |
|---|---|---|
| Bechdel analysis covers 1,615 films from 1990 to 2013 | 1,615 films | Yes |
| Films that pass return $2.68 per dollar of budget worldwide, films that fail return $2.45 | $2.70 and $2.45 | Fail matches exactly. Pass is 2 cents off. |
| 437 Fandango films had at least one review | 437 | Yes |
| 98% of those had 3 stars or more, 75% had 4 or more | 98.2% and 74.8% | Yes |
| Petroleum Engineering is the top-paid major at $110,000 | $110,000 | Yes |

The one that did not match exactly is the $2.68. My median for passing films is $2.70. I checked that I had the same 1,615 films, so my best guess is that it comes from how the median is taken or which rows with missing gross are left out (11 films have no worldwide gross). I could not pin it down further.

## Dataset 1: college majors

Queries: [`queries/01_college_majors.sql`](queries/01_college_majors.sql). Output: [`results/01_college_majors.txt`](results/01_college_majors.txt)

**The top of the list is all engineering.** Petroleum Engineering ($110,000) is followed by Mining, Metallurgical, Naval and Chemical Engineering. The bottom is Library Science at $22,000, then three psychology majors.

**Averaging has to be weighted.** A plain `AVG(median)` by category treats a major with 600 graduates the same as one with 300,000. Weighting by number of graduates moves several categories a lot. Law & Public Policy drops from $42,200 to $35,729, because its biggest major (Criminal Justice) pays less than its small ones.

**Majors with more women pay less, and it is not only because of engineering.** In majors that are under 25% women the average median is $53,496. In majors that are 75% or more women it is $33,074. I expected that to disappear once engineering was removed, since engineering is both the best paid and the most male. It shrinks but does not go away: $40,574 against $34,605.

**About half of employed recent grads are in jobs that do not need a degree.** Across every major it is 51.9%. For Political Science it is 64.5%, with 10.1% unemployment on top of that.

**Joining the two files: a graduate degree is worth the most where the bachelor's is worth the least.** In Biology & Life Science, people with a graduate degree earn 54.8% more than people who stopped at a bachelor's. In Engineering it is 19.2%. For Petroleum Engineering the premium is actually negative (-2%). The extreme case is Health and Medical Preparatory Programs at 165%, which makes sense, since that major is basically pre-med and the graduate degree is medical school.

## Dataset 2: the Bechdel test

Queries: [`queries/02_bechdel.sql`](queries/02_bechdel.sql). Output: [`results/02_bechdel.txt`](results/02_bechdel.txt)

A film passes if it has two named women who talk to each other about something other than a man.

**Fewer than half of films pass.** 46.6% from 1990 to 2013. The most common way to fail is not "no women in the movie" (7.9%). It is two women who never speak to each other (28.7%).

**It improved, then stopped.** 25.9% passed in the 1970s, 43.6% in the 1990s, 48.7% in the 2000s, and then 45.0% for 2010 to 2013.

**Passing films get less money.** The median budget is $31.1 million for films that pass and $48.4 million for films that fail, in 2013 dollars.

**But they earn more per dollar, which is the article's point.** $2.70 of worldwide gross per budget dollar against $2.45.

**My own check: is that only because cheap films have better returns?** Cheap films do have higher returns in general, and passing films are cheaper, so the gap could be a side effect of budget. I split the films into four budget bands and compared pass and fail inside each band. Passing films come out ahead in all four: under $20M (4.84 vs 4.59), $20M to $60M (3.47 vs 3.29), $60M to $120M (3.13 vs 2.82), and over $120M (3.56 vs 3.16). So the result holds even between films of similar size. This uses total gross over total budget within each band, which is a slightly different measure than the median above.

**The biggest films are the least likely to pass.** Only 31.8% of films with budgets over $120M pass, against 48.9% of everything else.

SQLite has no `MEDIAN()` function, so the median queries number the rows inside each group with `ROW_NUMBER()` and take the middle one.

## Dataset 3: Fandango ratings

Queries: [`queries/03_fandango.sql`](queries/03_fandango.sql). Output: [`results/03_fandango.txt`](results/03_fandango.txt)

**Almost nothing on Fandango is rated badly.** Of 437 films with at least one review, 98.2% show 3 stars or more and 74.8% show 4 or more. Only 3 films are under 2 stars.

**The stars only ever round up.** The file has both the stars shown on the site and the real average underneath. Out of 437 films, 109 are shown exactly, 328 are rounded up, and zero are rounded down. Normal rounding to the nearest half star would never move a rating by more than 0.2, but 24.7% of films were pushed up by 0.3 or more. One film, Turbo Kid, had a real average of 4.0 and was shown as 5 stars (it only had 2 votes).

**Fandango is the highest score for most films.** On the 146 films that also have Rotten Tomatoes, Metacritic and IMDb scores, with everything converted to a 5-point scale, the averages are: Fandango 4.09, IMDb 3.37, Metacritic users 3.26, Rotten Tomatoes users 3.19, Rotten Tomatoes critics 3.04, Metacritic critics 2.94. Fandango is the single highest of the six for 96 of the 146 films. Fandango calls 107 of them "4 stars or better". IMDb does that for 10.

**The surprise.** I expected Fandango to never be the lowest score, and that is wrong. For 6 films it is the lowest of all six sites.

**More reviews does not fix it.** I thought films with thousands of votes would settle toward a normal average. They go the other way: films with 10,000 or more votes average 4.54 stars, and none of them is below 3.5. Popular films are either better liked, or the people who buy tickets through Fandango already wanted to see them.

## What I would do next

- Find where the 2 cent difference in the Bechdel ROI comes from.
- The Bechdel file ends in 2013. With newer films I could check whether the pass rate started climbing again.
- Rerun everything on SQL Server to match the project directions exactly.
