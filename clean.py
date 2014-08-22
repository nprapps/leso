#!/usr/bin/env python

import csv
import xlrd
from datetime import datetime

from slugify import slugify

IMPORT_FILE = "src/LESO Jan 2006 to April 2014.xlsx"


def make_headers(worksheet):
    """Make headers"""
    headers = {}
    cell_idx = 0
    while cell_idx < worksheet.ncols:
        cell_type = worksheet.cell_type(0, cell_idx)
        cell_value = worksheet.cell_value(0, cell_idx)
        cell_value = slugify(cell_value).replace('-', '_')
        if cell_type == 1:
            headers[cell_idx] = cell_value
        cell_idx += 1

    return headers


def clean_dates(worksheet, writer, headers, datemode):
    row_idx = 1
    while row_idx < worksheet.nrows:
        cell_idx = 0
        row_dict = {}
        while cell_idx < worksheet.ncols:
            try:
                header = headers[cell_idx]
            except KeyError:
                cell_idx += 1
                continue

            if header == "ship_date":
                # clean date
                try:
                    cell_value = int(worksheet.cell_value(row_idx, cell_idx))
                    if cell_value > 20000000:
                        # turn into string and parse as YYYYMMDD
                        cell_value = str(cell_value)
                        cell_value = datetime.strptime(cell_value, "%Y%m%d")
                    else:
                        parts = xlrd.xldate_as_tuple(cell_value, datemode)
                        cell_value = datetime(*parts)
                except ValueError:
                    cell_value = None

            elif header == 'nsn':
                cell_value = str(worksheet.cell_value(row_idx, cell_idx))
                id_prefix = cell_value.split('-')[0]
                row_dict['id_category'] = id_prefix

                supercategory = id_prefix[:2]
                row_dict['supercategory'] = supercategory

            elif header == "quantity":
                try:
                    cell_value = int(worksheet.cell_value(row_idx, cell_idx))
                except ValueError:
                    cell_value = None

            else:
                try:
                    # Strings
                    cell_value = worksheet.cell_value(row_idx, cell_idx).strip()
                except AttributeError:
                    # Numbers
                    cell_value = worksheet.cell_value(row_idx, cell_idx)
            row_dict[header] = cell_value
            cell_idx += 1

        writer.writerow(row_dict)
        row_idx += 1


if __name__ == "__main__":
    workbook = xlrd.open_workbook(IMPORT_FILE)
    datemode = workbook.datemode
    worksheets = workbook.sheet_names()
    headers = make_headers(workbook.sheet_by_name(worksheets[0]))
    headers['id_category'] = 'id_category'
    headers['supercategory'] = 'supercategory'
    f = open("src/leso.csv", "w")
    writer = csv.DictWriter(f, fieldnames=headers.values())
    writer.writeheader()
    for worksheet in worksheets:
        sheet = workbook.sheet_by_name(worksheet)
        clean_dates(sheet, writer, headers, datemode)
