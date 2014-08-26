# LESO data

## Requirements

* bash
* Python
* PostgreSQL

## Installation

Install project requirements (preferably in a virtualenv):

   pip install -r requirements.txt

## Import the data

To clean the data and build the tables, run:

    ./build.sh

Each step can be run individually.

To import the data into a PostgreSQL database:

    ./import.sh

To generate summary tables as CSVs:

    ./summarize.sh

To generate db ready data files and per-state data files with FIPS codes and
pre-computed total cost columns:

    ./export.sh
