#!/bin/bash

# clean up dates and strings!
echo "Run clean.py to generate leso.csv"
./clean.py

# setup our database
echo "Create database"
dropdb --if-exists leso
createdb leso

# get leso csv in the db
echo "Import leso.csv to database"
psql leso -c "CREATE TABLE data (
  state char(2),
  station_name_lea varchar,
  nsn varchar,
  item_name varchar,
  quantity decimal,
  ui varchar,
  acquisition_cost decimal,
  demil_code varchar,
  demil_ic varchar,
  ship_date timestamp,
  federal_supply_category varchar,
  federal_supply_class varchar
);"
psql leso -c "COPY data FROM '`pwd`/src/leso.csv' DELIMITER ',' CSV HEADER;"

echo "Import federal supply codes to database"
psql leso -c "CREATE TABLE codes (
  CODE varchar(16),
  NAME text,
  START_DATE varchar,
  END_DATE varchar,
  FULL_NAME text,
  EXCLUDES text,
  NOTES text,
  INCLUDES text
);"
psql leso -c "COPY codes FROM '`pwd`/src/codes.csv' DELIMITER ',' CSV HEADER;"

# De-dupe the supply codes
psql leso -c "DELETE FROM codes USING codes codes2 WHERE codes.code=codes2.code AND codes.START_DATE > codes2.START_DATE;"

echo "Import agency.csv"
in2csv --sheet "State Agencies" src/States\ and\ Federal\ LEAs\ in\ LESO\ as\ of\ 27\ Aug\ 2014.xlsx > src/state_agencies.csv
in2csv --sheet "Federal Agencies" src/States\ and\ Federal\ LEAs\ in\ LESO\ as\ of\ 27\ Aug\ 2014.xlsx > src/federal_agencies.csv
in2csv --sheet "Tribal Agencies" src/States\ and\ Federal\ LEAs\ in\ LESO\ as\ of\ 27\ Aug\ 2014.xlsx > src/tribal_agencies.csv
csvstack -n "agency_type" -g "state,federal,tribal" src/state_agencies.csv src/federal_agencies.csv src/tribal_agencies.csv | csvcut -c "1,3,4" > src/agencies.csv

echo "Import agencies to database"
psql leso -c "CREATE TABLE agencies (
  agency_type varchar,
  state varchar,
  agency_name varchar
);"
psql leso -c "COPY agencies FROM '`pwd`/src/agencies.csv' DELIMITER ',' CSV HEADER;"
