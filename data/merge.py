#!/usr/bin/env python

import csv

LESO = "leso-clean.csv"
MRAPS = "mraps.csv"
HEADERS = ['state', 'county', 'name', 'unit', 'cost', 'date']

def merge_data(leso_data, mraps_data):
    for leso_row in leso_data:
        if leso_row['name'] == 'MINE RESISTANT VEHICLE':
            find_matches(leso_row, mraps_data)

def find_matches(leso_row, mraps_data):
    for mraps_row in mraps_data:
        print mraps_row['county'].strip()
        if leso_row['county'] == mraps_row['county'].strip():
            print mraps_row['county'].strip()


if __name__ == "__main__":
    leso_data = csv.DictReader(open(LESO), fieldnames=HEADERS)
    mraps_data = csv.DictReader(open(MRAPS), fieldnames=HEADERS)
    merge_data(leso_data, mraps_data)
