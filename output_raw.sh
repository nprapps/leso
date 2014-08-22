#!/bin/bash

echo "Generate raw CSV tables"
mkdir -p csv
psql leso -c "COPY (
    select * from population
) to '`pwd`/csv/population.csv' WITH CSV HEADER;"
psql leso -c "COPY (
    select * from codes
) to '`pwd`/csv/codes.csv' WITH CSV HEADER;"
psql leso -c "COPY (
    select * from fips
) to '`pwd`/csv/fips.csv' WITH CSV HEADER;"
psql leso -c "COPY (
    select * from data
) to '`pwd`/csv/data.csv' WITH CSV HEADER;"
psql leso -c "COPY (
    select * from acs
) to '`pwd`/csv/acs.csv' WITH CSV HEADER;"
