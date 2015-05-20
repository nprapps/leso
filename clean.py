#!/usr/bin/env python

import csv
import xlrd

from util import make_headers, clean_data

IMPORT_FILES = ['src/Alaska_Louisiana.xls', 'src/Massachussetts_Wyoming_Territories.xls']

if __name__ == "__main__":
    for i, filename in enumerate(IMPORT_FILES):
        workbook = xlrd.open_workbook(filename)
        datemode = workbook.datemode
        worksheets = workbook.sheet_names()

        if i == 0:
            headers = make_headers(workbook.sheet_by_name(worksheets[0]))
            headers['federal_supply_class'] = 'federal_supply_class'
            headers['federal_supply_category'] = 'federal_supply_category'
            f = open("src/leso.csv", "w")
            writer = csv.DictWriter(f, fieldnames=headers.values())
            writer.writeheader()

        for worksheet in worksheets:
            sheet = workbook.sheet_by_name(worksheet)
            clean_data(sheet, writer, headers, datemode)
