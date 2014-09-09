#!/usr/bin/env python

import csv
import xlrd
import os
import pprint
from util import clean_data

OFFSETS = {
    'AR': 5,
    'CO': 5,
    'GA': 5,
    'IA': 5,
    'MT': 5,
    'ND': 5,
    'NE': 5,
    'NV': 5,
    'TX': 1,
    'WA': 5,
    'WI': 3,
}

DEFAULT_HEADERS = [
    'agency_name',
    'book_type',
    'county',
    'demil_code',
    'demil_ic',
    'dodaac',
    'dtid',
    'federal_supply_category',
    'federal_supply_class',
    'image_count',
    'item_name',
    'inventory_date',
    'nsn',
    'property_number',
    'property_status',
    'quantity',
    'requisition_date',
    'requisition_number',
    'row',
    'serial_number',
    'serial_number_required_flag',
    'ship_date',
    'state',
    'station_active_flag',
    'station_type',
    'total_cost',
    'ui',
    'unit_cost',
]

if __name__ == "__main__":
    all_data = []
    for filename in os.listdir('src/state_specific'):
        if filename.endswith('.xlsx'):
            state = filename[0:-5]
            workbook = xlrd.open_workbook('src/state_specific/%s' % filename)
            datemode = workbook.datemode
            worksheets = workbook.sheet_names()

            if state in OFFSETS.keys():
                start_row = OFFSETS[state]
            else:
                start_row = 0

            for worksheet in worksheets:
                sheet = workbook.sheet_by_name(worksheet)
                data = clean_data(sheet, datemode, start_row)
                for row in data:
                    row["state"] = state
                    if "row" in row.keys():
                        del row["row"]
                all_data += data

    f = open("src/state-specific.csv", "w")
    writer = csv.DictWriter(f, fieldnames=DEFAULT_HEADERS)
    writer.writeheader()
    for row in all_data:
        writer.writerow(row)
        # try:
        # except ValueError:
        #     import ipdb; ipdb.set_trace();
        #     print ""

