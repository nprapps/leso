#!/bin/bash

# clean up dates and strings!

if [ $1 != "skip-clean" ]
then
  echo "Run clean.py to generate leso.csv"
  ./clean.py
fi

# setup our database
echo "Create database"
dropdb --if-exists leso
createdb leso
psql leso -c "CREATE EXTENSION postgis;"
psql leso -c "CREATE EXTENSION postgis_topology"
psql leso -c "SELECT postgis_full_version()"

# get leso csv in the db
echo "Import leso.csv to database"
psql leso -c "CREATE TABLE data (
  state char(2),
  county varchar,
  nsn varchar,
  item_name varchar,
  quantity decimal,
  ui varchar,
  acquisition_cost decimal,
  ship_date timestamp,
  supercategory varchar,
  id_category varchar
);"
psql leso -c "COPY data FROM '`pwd`/src/leso.csv' DELIMITER ',' CSV HEADER;"

echo "Import FIPS crosswalk"
psql leso -c "CREATE TABLE fips (
  county varchar,
  state varchar,
  fips varchar
);"
psql leso -c "COPY fips FROM '`pwd`/src/fips_crosswalk.csv' DELIMITER ',' CSV HEADER;"


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

echo "Import ACS 5 year data"
psql leso -c "CREATE TABLE acs(
  census_id VARCHAR,
  fips VARCHAR,
  place_name VARCHAR,
  total INTEGER,
  total_error VARCHAR,
  white_alone INTEGER,
  white_alone_error NUMERIC,
  black_alone INTEGER,
  black_alone_error NUMERIC,
  indian_alone INTEGER,
  indian_alone_error NUMERIC,
  asian_alone INTEGER,
  asian_alone_error NUMERIC,
  hawaiian_alone INTEGER,
  hawaiian_alone_error NUMERIC,
  other_race_alone INTEGER,
  other_race_alone_error NUMERIC,
  two_or_more_races INTEGER,
  two_or_more_races_error NUMERIC,
  two_or_more_races_including INTEGER,
  two_or_more_races_including_error NUMERIC,
  two_or_more_races_excluding INTEGER,
  two_or_more_races_excluding_error NUMERIC
);"
PGCLIENTENCODING=LATIN1 psql leso -c "COPY acs FROM '`pwd`/src/census/acs_12_5yr_b02001.csv' DELIMITER ',' CSV"

echo "Generate population view"
psql leso -c "CREATE OR REPLACE VIEW population as select d.state, d.county,
    a.total, a.white_alone, a.black_alone, a.indian_alone, a.asian_alone, a.hawaiian_alone, a.other_race_alone, a.two_or_more_races, a.two_or_more_races_including, a.two_or_more_races_excluding,
    (a.white_alone::numeric/a.total::numeric * 100) as white_percentage, (a.black_alone::numeric/a.total::numeric * 100) as black_percentage, (a.indian_alone::numeric/a.total::numeric * 100) as indian_percentage, (a.asian_alone::numeric/a.total::numeric * 100) as asian_percentage, (a.other_race_alone::numeric/a.total::numeric * 100) as other_race_percentage,
    sum((d.quantity * d.acquisition_cost)) as total_cost, (sum((d.quantity * d.acquisition_cost))/a.total) as cost_per_capita
  from data as d
  join fips as f on d.state = f.state and d.county = f.county
  join acs as a on f.fips = a.fips
  group by d.state, d.county, a.total, a.white_alone, a.black_alone, a.indian_alone, a.asian_alone, a.hawaiian_alone, a.other_race_alone, a.two_or_more_races, a.two_or_more_races_including, a.two_or_more_races_excluding;"

if [ ! -f "./tl_2013_us_county.zip" ]
then
  echo "Get county TIGER data"
  curl -O http://www2.census.gov/geo/tiger/TIGER2013/COUNTY/tl_2013_us_county.zip
  unzip tl_2013_us_county.zip -d tl_2013_us_county
fi

# import the geo data
# gotta set the client encoding -- the import fails otherwise
echo "Import geo data"
PGCLIENTENCODING=LATIN1 ogr2ogr -f PostgreSQL PG:dbname=leso tl_2013_us_county/tl_2013_us_county.shp -t_srs EPSG:900913 -nlt multipolygon -nln tl_2013_us_county

