#!/bin/bash

echo "Generate raw CSV tables"
mkdir -p export/db
psql leso -c "COPY population to '`pwd`/export/db/population.csv' WITH CSV HEADER;"
psql leso -c "COPY codes to '`pwd`/export/db/codes.csv' WITH CSV HEADER;"
psql leso -c "COPY fips to '`pwd`/export/db/fips.csv' WITH CSV HEADER;"
psql leso -c "COPY data to '`pwd`/export/db/data.csv' WITH CSV HEADER;"
psql leso -c "COPY acs to '`pwd`/export/db/acs.csv' WITH CSV HEADER;"
psql leso -c "COPY agencies to '`pwd`/export/db/agencies.csv' WITH CSV HEADER;"

echo "Export state data"
mkdir -p export/states
psql leso -t -A -c "select distinct(state) from data" | while read STATE; do
  echo "Creating export/states/$STATE.csv"
  psql leso -c "COPY (
    select d.state,
        d.county,
        f.fips,
        d.nsn,
        d.item_name,
        d.quantity,
        d.ui,
        d.acquisition_cost,
        d.quantity * d.acquisition_cost as total_cost,
        d.ship_date,
        d.federal_supply_category,
        sc.name as federal_supply_category_name,
        d.federal_supply_class,
        c.full_name as federal_supply_class_name
      from data as d
      join fips as f on d.state = f.state and d.county = f.county
      join codes as c on d.federal_supply_class = c.code
      join codes as sc on d.federal_supply_category = sc.code
      where d.state='$STATE'
    ) to '`pwd`/export/states/$STATE.csv' WITH CSV HEADER;"
done

echo "Creating export/states/all_states.csv"
psql leso -c "COPY (
  select d.state,
    d.county,
    f.fips,
    d.nsn,
    d.item_name,
    d.quantity,
    d.ui,
    d.acquisition_cost,
    d.quantity * d.acquisition_cost as total_cost,
    d.ship_date,
    d.federal_supply_category,
    sc.name as federal_supply_category_name,
    d.federal_supply_class,
    c.full_name as federal_supply_class_name
  from data as d
  join fips as f on d.state = f.state and d.county = f.county
  join codes as c on d.federal_supply_class = c.code
  join codes as sc on d.federal_supply_category = sc.code
) to '`pwd`/export/states/all_states.csv' WITH CSV HEADER;"
