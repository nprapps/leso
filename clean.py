#!/usr/bin/env python

import csv
import xlrd

from util import make_headers, clean_data

IMPORT_FILE = "src/LESO Jan 2006 to April 2014.xlsx"

if __name__ == "__main__":
    workbook = xlrd.open_workbook(IMPORT_FILE)
    datemode = workbook.datemode
    worksheets = workbook.sheet_names()
    headers = make_headers(workbook.sheet_by_name(worksheets[0]))
    headers['federal_supply_class'] = 'federal_supply_class'
    headers['federal_supply_category'] = 'federal_supply_category'
    f = open("src/leso.csv", "w")
    writer = csv.DictWriter(f, fieldnames=headers.values())
    writer.writeheader()
    for worksheet in worksheets:
        sheet = workbook.sheet_by_name(worksheet)
        clean_data(sheet, writer, headers, datemode)
