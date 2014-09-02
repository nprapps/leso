#!/usr/bin/env python

import csv
import xlrd
from util import clean_data

IMPORT_FILE = "src/LESO Jan 2006 to April 2014.xlsx"

if __name__ == "__main__":
    workbook = xlrd.open_workbook(IMPORT_FILE)
    datemode = workbook.datemode
    worksheets = workbook.sheet_names()
    for worksheet in worksheets:
        sheet = workbook.sheet_by_name(worksheet)
        data = clean_data(sheet, datemode)

    headers = data[0].keys()
    headers.sort()

    f = open("src/leso.csv", "w")
    writer = csv.DictWriter(f, fieldnames=headers)
    writer.writeheader()
    for row in data:
        writer.writerow(row)
