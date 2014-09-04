#!/bin/bash

echo "Generate raw CSV tables"
mkdir -p export/db
psql leso -c "COPY (select * from population) to '`pwd`/export/db/population.csv' WITH CSV HEADER;"
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

echo "Creating state specific dumps"
mkdir -p export/states/specific
psql leso -t -A -c "select distinct(state) from state_specific" | while read STATE; do
  echo "Creating export/states/specific/$STATE.csv"
  psql leso -c "COPY (
    select s.agency_name,
      s.item_name,
      s.quantity,
      s.ui,
      s.unit_cost,
      s.total_cost,
      s.county,
      s.ship_date,
      s.station_type,
      s.federal_supply_category,
      sc.name as federal_supply_category_name,
      s.federal_supply_class,
      c.full_name as federal_supply_class_name,
      s.book_type,
      s.demil_code,
      s.demil_ic,
      s.dodaac,
      s.dtid,
      s.image_count,
      s.inventory_date,
      s.property_number,
      s.property_status,
      s.requisition_date,
      s.requisition_number,
      s.serial_number,
      s.serial_number_required_flag,
      s.station_active_flag
    from state_specific as s
    left join codes as c on s.federal_supply_class = c.code
    left join codes as sc on s.federal_supply_category = sc.code
    where s.state='$STATE'
  ) to '`pwd`/export/states/specific/$STATE.csv' WITH CSV HEADER;"
done
