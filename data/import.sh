#!/bin/bash

# clean up dates and strings!
# echo "Run clean.py to generate leso.csv"
# ./clean.py

# setup our database
echo "Create database"
dropdb --if-exists leso
createdb leso
psql leso -c "CREATE EXTENSION postgis;"
psql leso -c "CREATE EXTENSION postgis_topology"
psql leso -c "SELECT postgis_full_version()"

# get leso csv in the db
psql leso -c "CREATE TABLE data (STATE char(2), COUNTY varchar, ID varchar, NAME varchar, UNIT varchar, UI varchar, COST varchar, DATE varchar);"
psql leso -c "COPY data FROM '`pwd`/leso.csv' DELIMITER ',' CSV;"

psql leso -c "CREATE TABLE codes (CODE varchar(16), NAME text, START_DATE varchar, END_DATE varchar, FULL_NAME text, EXCLUDES text, NOTES text, INCLUDES text)"
psql leso -c "COPY codes FROM '`pwd`/codes.csv' DELIMITER ',' CSV;"

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

# merge with geo data
