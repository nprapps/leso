#!/bin/bash

echo 'IMPORT THE DATA'
./import.sh

echo 'CREATE THE OUTPUT FILES'
./output.sh

echo 'GENERATE STATE FILES'
./generate_states.sh

echo 'GENERATE RAW CSVs FOR OTHER DBs'
./output_raw.sh
