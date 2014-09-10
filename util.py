import xlrd

from datetime import datetime
from slugify import slugify


def make_headers(worksheet, header_row=0):
    """Make headers"""
    headers = {}
    cell_idx = 0
    while cell_idx < worksheet.ncols:
        cell_type = worksheet.cell_type(header_row, cell_idx)
        cell_value = worksheet.cell_value(header_row, cell_idx)
        cell_value = slugify(unicode(cell_value)).replace('-', '_')
        if cell_type == 1:
            headers[cell_idx] = cell_value
        cell_idx += 1

    return headers


def clean_data(worksheet, datemode, start_row=0):
    headers = make_headers(worksheet, start_row)
    row_idx = start_row + 1
    data = []
    while row_idx < worksheet.nrows:
        cell_idx = 0
        row_dict = {}
        while cell_idx < worksheet.ncols:
            try:
                header = headers[cell_idx]
            except KeyError:
                cell_idx += 1
                continue

            if header == "agency" or header == "lea" or header == "station_name_lea" or header == "law_enforcement_agency":
                header = "agency_name"

            if header == "qty":
                header = "quantity"

            if header == "acquisition_cost_per_unit" or header == "item_value":
                header = "unit_cost"

            if header == "total_value":
                header = "total_cost"

            if header == "transaction_date":
                header = "ship_date"

            if header == "last_inventory_date":
                header = "inventory_date"

            if header == "ship_date" or header == "inventory_date" or header == "requisition_date":
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
                row_dict['federal_supply_class'] = id_prefix

                federal_supply_category = id_prefix[:2]
                row_dict['federal_supply_category'] = federal_supply_category

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

        data.append(row_dict)
        row_idx += 1

    return data
