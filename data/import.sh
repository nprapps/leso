#!/bin/bash

# unfortunately, csvkit chokes on the dates in this file, so had to save the sheets manually
#in2csv --sheet "STATES A-F" --no-inference LESO\ Jan\ 2006\ to\ April\ 2014.xlsx > a-f.csv
#in2csv --sheet "STATES G-M" --no-inference LESO\ Jan\ 2006\ to\ April\ 2014.xlsx > g-m.csv
#in2csv --sheet "STATES N-S" --no-inference LESO\ Jan\ 2006\ to\ April\ 2014.xlsx > n-s.csv
#in2csv --sheet "STATES T-W" --no-inference LESO\ Jan\ 2006\ to\ April\ 2014.xlsx > t-w.csv

# stack 'em up!
echo "Stack alphabetical files to create leso.csv"
csvstack a-f.csv g-m.csv n-s.csv t-w.csv > leso.csv

# clean up ship date column
#TODO

# csvkit works a-ok for mraps
echo "Generate mraps.csv"
in2csv --sheet "cleaned data" --no-inference MRAPS\ by\ County\ as\ of\ 24\ July\ 2014.xlsx > mraps.csv

# merge the files
# make the cost columns the same
echo "Merge and clean to create stacked.csv"
sed -i '' -e 's/Acquisition Cost/Cost/' leso.csv
sed -i '' -e 's/Unit Cost/Cost/' mraps.csv
# and stack them
csvstack leso.csv mraps.csv > stacked.csv

# setup our database
echo "Create database"
dropdb --if-exists leso
createdb leso
psql leso -c "CREATE EXTENSION postgis;"
psql leso -c "SELECT postgis_full_version()"

echo "Get county TIGER data"
curl -O http://www2.census.gov/geo/tiger/TIGER2013/COUNTY/tl_2013_us_county.zip
unzip tl_2013_us_county -d tl_2013_us_county

# import the geo data
# gotta set the client encoding -- the import fails otherwise
echo "Import geo data"
PGCLIENTENCODING=LATIN1 ogr2ogr -f PostgreSQL PG:dbname=leso tl_2013_us_county/tl_2013_us_county.shp -t_srs EPSG:900913 -nlt multipolygon -nln tl_2013_us_county

# merge with geo data
