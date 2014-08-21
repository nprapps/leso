mkdir -p build

echo "Generate unit distribution"
psql leso -c "COPY (select ui, count(*), sum(quantity) as total_quantity, sum((quantity*acquisition_cost)) as total_cost from data group by ui order by count desc) to '`pwd`/build/unit_distribution.csv' WITH CSV HEADER;"

echo "Generate category distribution"
psql leso -c "COPY (
select c.full_name, c.code as federal_supply_code,
  sum((d.quantity * d.acquisition_cost)) as total_cost
  from data as d
  join codes as c on d.id_category = c.code
  group by c.full_name, c.code
  order by c.full_name
) to '`pwd`/build/category_distribution.csv' WITH CSV HEADER;"

echo "Generate supercategory distirbution"
psql leso -c "COPY (
select c.name, c.code as supercategory_code,
  sum((d.quantity * d.acquisition_cost)) as total_cost
  from data as d
  join codes as c on d.supercategory = c.code
  group by c.name, c.code
  order by c.name
) to '`pwd`/build/supercategory_distribution.csv' WITH CSV HEADER;"

echo "Generate item name distribution with units"
psql leso -c "COPY (
select d.item_name, c.full_name, c.code as federal_supply_code, d.ui,
  sum(quantity) as total_quantity, sum((d.quantity * d.acquisition_cost)) as total_cost
  from data as d
  join codes as c on d.id_category = c.code
  group by c.full_name, c.code, d.item_name, d.ui
  order by d.item_name
) to '`pwd`/build/item_name_distribution_with_units.csv' WITH CSV HEADER;"

echo "Generate item name distribution without units"
psql leso -c "COPY (
select d.item_name, c.full_name, c.code as federal_supply_code,
  sum((d.quantity * d.acquisition_cost)) as total_cost
  from data as d
  join codes as c on d.id_category = c.code
  group by c.full_name, c.code, d.item_name
  order by d.item_name
) to '`pwd`/build/item_name_distribution.csv' WITH CSV HEADER;"

echo "Generate population table"
psql leso -c "COPY (select * from population) to '`pwd`/build/cost_by_population.csv' WITH CSV HEADER;"

echo "top 10 counties per capita"
psql leso -c "COPY (select * from population order by cost_per_capita limit 10) to '`pwd`/build/top_ten_per_capita.csv' WITH CSV HEADER"

echo "top 10 counties overall"
psql leso -c "COPY (select * from population order by total_cost desc limit 10) to '`pwd`/build/top_ten_overall.csv' WITH CSV HEADER"

echo "Generate gun table"
psql leso -c "COPY (
select d.state, d.county, a.total, count(d.item_name), count(d.item_name)/a.total::numeric as per_capita, sum(d.quantity * d.acquisition_cost) as total_cost from data as d
    join fips as f on d.state = f.state and d.county = f.county
    join acs as a on f.fips = a.fips
  where
    item_name='GUNS, THROUGH 30MM' or
    item_name='PISTOL, 40CAL, GLOCK GEN 3' or
    item_name='PISTOL,CALIBER .45,AUTOMATIC' or
    item_name='PISTON,GUN GAS CYLI' or
    item_name='RIFLE,4.5 MILLIMETE' or
    item_name='RIFLE,4.5 MILLIMETERS' or
    item_name='RIFLE,5.56 MILLIMETER' or
    item_name='RIFLE,7.62 MILLIMETER' or
    item_name='SHOTGUN,12 GAGE' or
    item_name='SHOTGUN,12 GAGE RIOT TYPE' or
    item_name='REVOLVER,CALIBER .38 SPECIAL'
  group by d.state, d.county, a.total
  order by per_capita desc
) to '`pwd`/build/guns_by_county.csv' WITH CSV HEADER;"

echo "Generate weapons table"
psql leso -c "COPY (
  select item_name, sum(quantity) as total_quantity, sum(quantity * acquisition_cost) as total_cost
  from data
  where
    item_name='GUNS, THROUGH 30MM' or
    item_name='PISTOL, 40CAL, GLOCK GEN 3' or
    item_name='PISTOL,CALIBER .45,AUTOMATIC' or
    item_name='PISTON,GUN GAS CYLI' or
    item_name='RIFLE,4.5 MILLIMETE' or
    item_name='RIFLE,4.5 MILLIMETERS' or
    item_name='RIFLE,5.56 MILLIMETER' or
    item_name='RIFLE,7.62 MILLIMETER' or
    item_name='SHOTGUN,12 GAGE' or
    item_name='SHOTGUN,12 GAGE RIOT TYPE' or
    item_name='REVOLVER,CALIBER .38 SPECIAL'
  group by item_name order by total_cost desc
) to '`pwd`/build/guns_by_item.csv' WITH CSV HEADER;"

echo "Generate weapons table"
psql leso -c "COPY (
  select item_name, sum(quantity) as total_quantity, sum(quantity * acquisition_cost) as total_cost
  from data where supercategory = '10'
  group by item_name order by total_cost desc
) to '`pwd`/build/weapons_by_item.csv' WITH CSV HEADER;"

echo "Generate VA table"
psql leso -c "COPY (
  SELECT state, county, item_name, ship_date, quantity, acquisition_cost from data
    where state = 'VA' and county = 'ARLINGTON' or
    state = 'VA' and county = 'TAZEWELL' or
    state = 'VA' and county = 'PAGE'
    group by state, county, item_name, ship_date, quantity, acquisition_cost
    order by county
) to '`pwd`/build/arlington_page_tazewell.csv' WITH CSV HEADER;"

echo "Generate musical instruments table"
psql leso -c "COPY (
  select state, county, item_name, ship_date, quantity, acquisition_cost, quantity * acquisition_cost as total_cost from data where id_category = '7710' or id_category = '7720'
) to '`pwd`/build/musical_instruments.csv' WITH CSV HEADER;"

echo "Generate night vision table"
psql leso -c "COPY (
  select item_name, sum(quantity) as total_quantity, sum(quantity * acquisition_cost) as total_cost
  from data where id_category = '5855'
  group by item_name order by total_cost desc
) to '`pwd`/build/night_vision_by_item.csv' WITH CSV HEADER;"