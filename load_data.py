"""Load the FiveThirtyEight CSV files into a SQLite database.

The project directions use SQL Server and BULK INSERT. I am on a Mac without
SQL Server, so this does the same job with SQLite: read each CSV, create a
table with real column types, and insert the rows.

Run:  python load_data.py        (creates fivethirtyeight.db)
"""
import csv
import sqlite3

DB = "fivethirtyeight.db"

# table name -> (csv file, {column name in csv: (column name in table, type)})
TABLES = {
    "recent_grads": ("data/recent-grads.csv", {
        "Rank": ("rank", "INTEGER"), "Major_code": ("major_code", "INTEGER"), "Major": ("major", "TEXT"),
        "Total": ("total", "INTEGER"), "Men": ("men", "INTEGER"), "Women": ("women", "INTEGER"),
        "Major_category": ("major_category", "TEXT"), "ShareWomen": ("share_women", "REAL"),
        "Sample_size": ("sample_size", "INTEGER"), "Employed": ("employed", "INTEGER"),
        "Full_time": ("full_time", "INTEGER"), "Part_time": ("part_time", "INTEGER"),
        "Unemployed": ("unemployed", "INTEGER"), "Unemployment_rate": ("unemployment_rate", "REAL"),
        "Median": ("median", "INTEGER"), "P25th": ("p25th", "INTEGER"), "P75th": ("p75th", "INTEGER"),
        "College_jobs": ("college_jobs", "INTEGER"), "Non_college_jobs": ("non_college_jobs", "INTEGER"),
        "Low_wage_jobs": ("low_wage_jobs", "INTEGER")}),
    "grad_students": ("data/grad-students.csv", {
        "Major_code": ("major_code", "INTEGER"), "Major": ("major", "TEXT"),
        "Major_category": ("major_category", "TEXT"), "Grad_total": ("grad_total", "INTEGER"),
        "Grad_unemployment_rate": ("grad_unemployment_rate", "REAL"), "Grad_median": ("grad_median", "INTEGER"),
        "Nongrad_total": ("nongrad_total", "INTEGER"),
        "Nongrad_unemployment_rate": ("nongrad_unemployment_rate", "REAL"),
        "Nongrad_median": ("nongrad_median", "INTEGER"), "Grad_share": ("grad_share", "REAL"),
        "Grad_premium": ("grad_premium", "REAL")}),
    "bechdel": ("data/movies.csv", {
        "year": ("year", "INTEGER"), "imdb": ("imdb", "TEXT"), "title": ("title", "TEXT"),
        "clean_test": ("clean_test", "TEXT"), "binary": ("result", "TEXT"),
        "budget": ("budget", "INTEGER"), "domgross": ("domgross", "INTEGER"), "intgross": ("intgross", "INTEGER"),
        "budget_2013$": ("budget_2013", "INTEGER"), "domgross_2013$": ("domgross_2013", "INTEGER"),
        "intgross_2013$": ("intgross_2013", "INTEGER")}),
    "fandango_all": ("data/fandango_scrape.csv", {
        "FILM": ("film", "TEXT"), "STARS": ("stars", "REAL"), "RATING": ("rating", "REAL"),
        "VOTES": ("votes", "INTEGER")}),
    "fandango_compare": ("data/fandango_score_comparison.csv", {
        "FILM": ("film", "TEXT"), "RottenTomatoes": ("rt_critics", "INTEGER"),
        "RottenTomatoes_User": ("rt_users", "INTEGER"), "Metacritic": ("metacritic", "INTEGER"),
        "Metacritic_User": ("metacritic_users", "REAL"), "IMDB": ("imdb", "REAL"),
        "Fandango_Stars": ("fandango_stars", "REAL"), "Fandango_Ratingvalue": ("fandango_rating", "REAL"),
        "RT_norm": ("rt_critics_5", "REAL"), "RT_user_norm": ("rt_users_5", "REAL"),
        "Metacritic_norm": ("metacritic_5", "REAL"), "Metacritic_user_nom": ("metacritic_users_5", "REAL"),
        "IMDB_norm": ("imdb_5", "REAL"), "Fandango_votes": ("fandango_votes", "INTEGER")}),
}


def convert(value, sql_type):
    """Turn a CSV string into the right Python type. Blank and #N/A become NULL."""
    value = value.strip()
    if value in ("", "#N/A", "NA", "N/A"):
        return None
    if sql_type == "INTEGER":
        return int(float(value))
    if sql_type == "REAL":
        return float(value)
    return value.replace("&amp;", "&").replace("&#39;", "'")   # a few movie titles have HTML leftovers


def main():
    conn = sqlite3.connect(DB)
    for table, (path, columns) in TABLES.items():
        conn.execute(f"DROP TABLE IF EXISTS {table}")
        column_sql = ", ".join(f"{name} {sql_type}" for name, sql_type in columns.values())
        conn.execute(f"CREATE TABLE {table} ({column_sql})")
        with open(path, newline="", encoding="utf-8") as f:
            rows = [[convert(row[csv_name], sql_type) for csv_name, (_, sql_type) in columns.items()]
                    for row in csv.DictReader(f)]
        placeholders = ", ".join("?" for _ in columns)
        conn.executemany(f"INSERT INTO {table} VALUES ({placeholders})", rows)
        nulls = sum(value is None for row in rows for value in row)
        print(f"{table:17} {len(rows):5} rows   {len(columns):2} columns   {nulls:4} empty values")
    conn.commit()
    conn.close()


if __name__ == "__main__":
    main()
