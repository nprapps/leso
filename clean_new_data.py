#!/usr/bin/env python

import csv
import xlrd

from util import make_headers, clean_data

IMPORT_FILE = "src/All States_08202014_release.xlsx"


if __name__ == "__main__":
    workbook = xlrd.open_workbook(IMPORT_FILE)
    datemode = workbook.datemode
    worksheets = workbook.sheet_names()

    general_headers = make_headers(workbook.sheet_by_name(worksheets[0]))
    general_headers['federal_supply_class'] = 'federal_supply_class'
    general_headers['federal_supply_category'] = 'federal_supply_category'

    tactical_headers = make_headers(workbook.sheet_by_name(worksheets[1]))
    tactical_headers['federal_supply_class'] = 'federal_supply_class'
    tactical_headers['federal_supply_category'] = 'federal_supply_category'

    gf = open("src/updated_general.csv", "w")
    general_writer = csv.DictWriter(gf, fieldnames=general_headers.values())
    general_writer.writeheader()

    tf = open("src/updated_tactical.csv", "w")
    tactical_writer = csv.DictWriter(tf, fieldnames=tactical_headers.values())
    tactical_writer.writeheader()

    for worksheet in worksheets:
        sheet = workbook.sheet_by_name(worksheet)
        if worksheet.endswith("General"):
            clean_data(sheet, general_writer, general_headers, datemode)
        elif worksheet.endswith("Tactical"):
            clean_data(sheet, tactical_writer, tactical_headers, datemode)
