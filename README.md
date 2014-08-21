# LESO data

To clean the data and build the tables, run:

    ./build.sh

Each step can be run individually.

To import the data into a PostgreSQL database:

    ./import.sh

To generate summary tables as CSVs:

    ./output.sh

To generate per-state raw data files (with FIPS codes and pre-computed 
total cost columns):

    ./generate_states.sh
