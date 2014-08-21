#!/bin/bash

psql leso -t -A -c "select distinct(state) from data" | while read STATE; do
  echo "$STATE.csv"
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
      d.supercategory as federal_supply_category,
      d.id_category as federal_supply_class,
      c.full_name as federal_supply_class_name
    from data as d
    join fips as f on d.state = f.state and d.county = f.county
    join codes as c on d.id_category = c.code
    where d.state='$STATE'
  ) to '`pwd`/state_data/$STATE.csv' WITH CSV HEADER;"
done
