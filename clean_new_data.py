#!/usr/bin/env python

import csv
import xlrd
import os
import pprint
from util import clean_data

if __name__ == "__main__":
    for filename in os.listdir('src/state_specific'):
        if filename.endswith('.xlsx'):
            workbook = xlrd.open_workbook('src/state_specific/%s' % filename)
            datemode = workbook.datemode
            worksheets = workbook.sheet_names()
            for worksheet in worksheets:
                sheet = workbook.sheet_by_name(worksheet)
                data = clean_data(sheet, datemode)
            pprint.pprint(data)
