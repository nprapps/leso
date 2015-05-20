mkdir -p build

echo "Generate min date summary"
psql leso -c "COPY (select distinct(state), min(ship_date) from data group by state order by state) to '`pwd`/build/date_summary.csv' with CSV HEADER;"

echo "Generate unit distribution"
psql leso -c "COPY (select ui, count(*), sum(quantity) as total_quantity, sum((quantity*acquisition_cost)) as total_cost from data where ship_date >= '2006-01-01 00:00:00' group by ui order by count desc) to '`pwd`/build/unit_distribution.csv' WITH CSV HEADER;"

echo "Generate category distribution"
psql leso -c "COPY (
select c.full_name, c.code as federal_supply_class,
  sum(d.quantity) as quantity,
  sum((d.quantity * d.acquisition_cost)) as total_cost
  from data as d
  join codes as c on d.federal_supply_class = c.code
  where d.ship_date >= '2006-01-01 00:00:00'
  group by c.full_name, c.code
  order by c.full_name
) to '`pwd`/build/category_distribution.csv' WITH CSV HEADER;"

echo "Generate supercategory distirbution"
psql leso -c "COPY (
select c.name,
  sum((d.quantity * d.acquisition_cost)) as total_cost
  from data as d
  join codes as c on d.federal_supply_category = c.code
  where d.ship_date >= '2006-01-01 00:00:00'
  group by c.name
  order by total_cost desc
) to '`pwd`/build/supercategory_distribution.csv' WITH CSV HEADER;"

echo "Create supercategory view"
psql leso -c "create or replace view supercategories as select c.name, c.code,
sum((d.quantity * d.acquisition_cost)) as total_cost
from data as d
join codes as c on d.federal_supply_category = c.code
group by c.name, c.code;"

echo "Generate top 10 supercategory time series"
psql leso -c "COPY (
select c.name, sum(quantity * acquisition_cost) as total_cost, extract(year from ship_date) as y from data as d join codes as c on d.federal_supply_category = c.code where federal_supply_category in (select code from supercategories order by total_cost desc limit 10) and ship_date >= '2006-01-01 00:00:00' group by c.name, y order by y desc
) to '`pwd`/build/supercategory_timeseries.csv' WITH CSV HEADER;"

echo "Generate airplane table"
psql leso -c "COPY (
  select item_name, sum(quantity) as total_quantity, sum(quantity * acquisition_cost) as total_cost
  from data where federal_supply_class = '1510' and ship_date >= '2006-01-01 00:00:00'
  group by item_name order by total_cost desc
) to '`pwd`/build/airplanes_by_item.csv' WITH CSV HEADER;"

echo "Generate helicopter table"
psql leso -c "COPY (
  select item_name, sum(quantity) as total_quantity, sum(quantity * acquisition_cost) as total_cost
  from data where federal_supply_class = '1520' and ship_date >= '2006-01-01 00:00:00'
  group by item_name order by total_cost desc
) to '`pwd`/build/helicopters_by_item.csv' WITH CSV HEADER;"

echo "Generate item name distribution with units"
psql leso -c "COPY (
select d.item_name, c.full_name, c.code as federal_supply_code, d.ui,
  sum(quantity) as total_quantity, sum((d.quantity * d.acquisition_cost)) as total_cost
  from data as d
  join codes as c on d.federal_supply_class = c.code
  where d.ship_date >= '2006-01-01 00:00:00'
  group by c.full_name, c.code, d.item_name, d.ui
  order by d.item_name
) to '`pwd`/build/item_name_distribution_with_units.csv' WITH CSV HEADER;"

echo "Generate item name distribution without units"
psql leso -c "COPY (
select d.item_name, c.full_name, c.code as federal_supply_code,
  sum((d.quantity * d.acquisition_cost)) as total_cost
  from data as d
  join codes as c on d.federal_supply_class = c.code
  where d.ship_date >= '2006-01-01 00:00:00'
  group by c.full_name, c.code, d.item_name
  order by d.item_name
) to '`pwd`/build/item_name_distribution.csv' WITH CSV HEADER;"

echo "Generate weapons table"
psql leso -c "COPY (
  select item_name, sum(quantity) as total_quantity, sum(quantity * acquisition_cost) as total_cost
  from data
  where
    (item_name='GUNS, THROUGH 30MM' or
    item_name='PISTOL, 40CAL, GLOCK GEN 3' or
    item_name='PISTOL,CALIBER .45,AUTOMATIC' or
    item_name='PISTON,GUN GAS CYLI' or
    item_name='RIFLE,4.5 MILLIMETE' or
    item_name='RIFLE,4.5 MILLIMETERS' or
    item_name='RIFLE,5.56 MILLIMETER' or
    item_name='RIFLE,7.62 MILLIMETER' or
    item_name='SHOTGUN,12 GAGE' or
    item_name='SHOTGUN,12 GAGE,RIOT TYPE' or
    item_name='REVOLVER,CALIBER .38 SPECIAL')
    and ship_date >= '2006-01-01 00:00:00'
  group by item_name order by total_cost desc
) to '`pwd`/build/guns_by_item.csv' WITH CSV HEADER;"

echo "Generate weapons table"
psql leso -c "COPY (
  select d.item_name, d.federal_supply_class, c.full_name, sum(d.quantity) as total_quantity, sum(d.quantity * d.acquisition_cost) as total_cost
  from data as d
  join codes as c on d.federal_supply_class = c.code
  where federal_supply_category = '10' and ship_date >= '2006-01-01 00:00:00'
  group by d.item_name, d.federal_supply_class, c.full_name order by total_cost desc
) to '`pwd`/build/weapons_by_item.csv' WITH CSV HEADER;"

echo "Generate night vision table"
psql leso -c "COPY (
  select item_name, sum(quantity) as total_quantity, sum(quantity * acquisition_cost) as total_cost
  from data where federal_supply_class = '5855' and ship_date >= '2006-01-01 00:00:00'
  group by item_name order by total_cost desc
) to '`pwd`/build/night_vision_by_item.csv' WITH CSV HEADER;"

# Bayonets
echo "Generate bayonet count"
psql leso -c "COPY (
    select sum(quantity) as quantity, sum(acquisition_cost * quantity) as total_cost
    from data
    where (item_name='BAYONET' or item_name='BAYONET-KNIFE' or item_name='BAYONET AND SCABBARD' or item_name='BAYONET,SEALAND' or item_name='BAYONET AND SCABBAR' or item_name='SCABBARD,BAYONET-KNIFE') and ship_date >= '2006-01-01 00:00:00'
) to '`pwd`/build/bayonets.csv' WITH CSV HEADER;"

echo "Generate grenade launcher count"
psql leso -c "COPY (
    select sum(quantity) as quantity, sum(acquisition_cost * quantity) as total_cost
    from data
    where item_name='LAUNCHER,GRENADE' and ship_date >= '2006-01-01 00:00:00'
) to '`pwd`/build/grenade_launchers.csv' WITH CSV HEADER;"

# Handy queries used to double check #s in reporting

# Grenade launchers
# select sum(quantity), sum(acquisition_cost * quantity) from data where item_name='LAUNCHER,GRENADE';

# Combat knives
# select sum(quantity), sum(acquisition_cost * quantity) from data where item_name='KNIFE,COMBAT' or item_name='KNIFE,COMBAT,WITH S' or item_name='KNIFE,COMBAT,WITH SHEATH';

# Cargo planes
# select sum(quantity), sum(acquisition_cost * quantity) from data where item_name='AIRPLANE,CARGO-TRANSPORT';

# Ordinance robots
# select sum(quantity), sum(acquisition_cost * quantity) from data where item_name='MK3MOD0' or item_name='ROBOT,EXPLOSIVE ORD' or item_name='ROBOT, EXPLOSIVE ORDINANCE DISPOSAL' or item_name='ROBOT,EXPLOSIVE,SPE';

# All helicopters
# select sum(quantity) from data where id_category='1520';

# All airplanes
# select sum(quantity) from data where id_category='1510';

