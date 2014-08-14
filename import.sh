#!/bin/bash

#unfortunately, csvkit chokes on the dates in this file, so had to save the sheets manually
#in2csv --sheet "STATES A-F" --no-inference LESO\ Jan\ 2006\ to\ April\ 2014.xlsx > a-f.csv
#in2csv --sheet "STATES G-M" --no-inference LESO\ Jan\ 2006\ to\ April\ 2014.xlsx > g-m.csv
#in2csv --sheet "STATES N-S" --no-inference LESO\ Jan\ 2006\ to\ April\ 2014.xlsx > n-s.csv
#in2csv --sheet "STATES T-W" --no-inference LESO\ Jan\ 2006\ to\ April\ 2014.xlsx > t-w.csv

#stack 'em up!
csvstack a-f.csv g-m.csv n-s.csv t-w.csv > leso.csv