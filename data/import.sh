#!/bin/bash

# clean up dates and strings!
echo "Run clean.py to generate leso.csv"
./clean.py

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
psql leso -c "COPY data FROM '`pwd`/leso.csv' DELIMITER ',' CSV HEADER;"

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
psql leso -c "COPY codes FROM '`pwd`/codes.csv' DELIMITER ',' CSV HEADER;"

# De-dupe the supply codes
psql leso -c "DELETE FROM codes USING codes codes2 WHERE codes.code=codes2.code AND codes.START_DATE > codes2.START_DATE;"

echo "Generate distributions"
psql leso -c "COPY (select full_name, id_category, ui, sum(quantity) as total_quantity, sum((acquisition_cost * quantity)) as total_cost from data join codes on data.id_category = codes.code group by id_category, full_name, ui) to '`pwd`/item_distribution_with_units.csv' WITH CSV HEADER;"
psql leso -c "COPY (select ui, count(*), sum(quantity) as total_quantity, sum((quantity*acquisition_cost)) as total_cost from data group by ui order by count desc) to '`pwd`/unit_distribution.csv' WITH CSV HEADER;"

psql leso -c "COPY (
select c.full_name, c.code as federal_supply_code,
  sum((d.quantity * d.acquisition_cost)) as total_cost,
  from data as d
  join codes as c on d.id_category = c.code
  group by c.full_name, c.code
  order by c.full_name
) to '`pwd`/category_distribution.csv' WITH CSV HEADER;"

psql leso -c "COPY (
select c.full_name, c.code as supercategory_code,
  sum((d.quantity * d.acquisition_cost)) as total_cost,
  from data as d
  join codes as c on d.supercategory = c.code
  group by c.full_name, c.code
  order by c.full_name
) to '`pwd`/supercategory_distribution.csv' WITH CSV HEADER;"

psql leso -c "COPY (
select d.item_name, c.full_name, c.code as federal_supply_code, d.ui,
  sum(quantity) as total_quantity, sum((d.quantity * d.acquisition_cost)) as total_cost, 
  from data as d
  join codes as c on d.id_category = c.code
  group by c.full_name, c.code, d.item_name, d.ui
  order by d.item_name
) to '`pwd`/item_name_distribution.csv' WITH CSV HEADER;"

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
