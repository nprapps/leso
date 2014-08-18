#!/bin/bash

# unfortunately, csvkit chokes on the dates in this file, so had to save the sheets manually
#in2csv --sheet "STATES A-F" --no-inference LESO\ Jan\ 2006\ to\ April\ 2014.xlsx > a-f.csv
#in2csv --sheet "STATES G-M" --no-inference LESO\ Jan\ 2006\ to\ April\ 2014.xlsx > g-m.csv
#in2csv --sheet "STATES N-S" --no-inference LESO\ Jan\ 2006\ to\ April\ 2014.xlsx > n-s.csv
#in2csv --sheet "STATES T-W" --no-inference LESO\ Jan\ 2006\ to\ April\ 2014.xlsx > t-w.csv

# clean up dates and strings!
echo "Run clean.py to generate leso.csv"
./clean.py

# get the columns we want
csvcut -c 1,2,4,5,7,8 leso.csv > leso-clean.csv

# csvkit works a-ok for mraps
echo "Generate mraps.csv"
in2csv --sheet "cleaned data" --no-inference MRAPS\ by\ County\ as\ of\ 24\ July\ 2014.xlsx > mraps.csv

# make the cost columns the same
echo "clean cost columns"
sed -i '' -e 's/Acquisition Cost/Cost/' leso-clean.csv
sed -i '' -e 's/Unit Cost/Cost/' mraps.csv

# echo "Run merge.py to merge mraps with leso"
# ./merge.py


# setup our database
echo "Create database"
dropdb --if-exists leso
createdb leso
psql leso -c "CREATE EXTENSION postgis;"
psql leso -c "CREATE EXTENSION postgis_topology"
psql leso -c "SELECT postgis_full_version()"

# get leso csv in the db
psql leso -c "CREATE TABLE data (STATE char(2), COUNTY varchar, NAME varchar, UNIT varchar, COST varchar, DATE varchar);"
psql leso -c "COPY data FROM '/Users/tylerfisher/src/leso/data/stacked.csv' DELIMITER ',' CSV;"

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
