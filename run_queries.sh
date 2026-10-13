#!/bin/sh
# Runs every query file and saves what it prints in results/.
# Usage: sh run_queries.sh     (run python load_data.py first)
for file in queries/*.sql; do
    name=$(basename "$file" .sql)
    sqlite3 -header -column fivethirtyeight.db < "$file" > "results/$name.txt"
    echo "ran $file -> results/$name.txt"
done
