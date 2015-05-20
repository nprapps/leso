# LESO data

*Update, 5-20-15: The scripts have been changed to use the [latest data dumps](http://www.dispositionservices.dla.mil/efoia-privacy/pages/ereadingroom.aspx) from the Defense Logisitics Agency. The new data shows equipment distribution to agencies rather than counties. The counts differ from the previous dataset, and summaries based on correlating census data with counties have been removed. The older workflow and data remains available in the "2014_county_data" branch.*

*These processing scripts are described in depth in the NPR Visuals blog post, [A Resuable Data Processing Workflow](http://blog.apps.npr.org/2014/09/02/reusable-data-processing.html).*

## Requirements

* bash
* Python
* PostgreSQL

## Installation

Install project requirements (preferably in a virtualenv):

```
pip install -r requirements.txt
```

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
