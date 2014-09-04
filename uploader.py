#!/usr/bin/env python

import json
import os

from pprint import pprint as pp

from os import listdir
from os.path import isfile, join

from apiclient.errors import HttpError
from apiclient.http import MediaFileUpload
from tarbell.oauth import get_drive_api_from_client_secrets

def upload(directory, folder_id, title_suffix, description_prefix):
    files = [ f for f in listdir(export_path) if isfile(join(export_path,f)) ]
    files.sort()
    files.reverse()
    for filename in files:
        name = filename[0:-4]
        media_body = MediaFileUpload(
            os.path.join(export_path, "%s" % filename), mimetype="text/csv")
        body = {
            "title": "{0}{1}".format(name, title_suffix),
            "description": "{0}{1}".format(description_prefix, name),
            "mimeType": "application/vnd.ms-excel",
            "parents": [{
                "kind": "drive#fileLink",
                "id": folder_id
            }]
        }
        try:
            print("Uploading {0}".format(filename))
            newfile = service.files().insert(body=body, media_body=media_body,
                convert=True).execute()
        except HttpError, e:
            error = json.loads(e.content)
            pp(error)


if __name__ == "__main__":

    secrets_path = os.path.expanduser("~/.tarbell/client_secrets.json")
    service = get_drive_api_from_client_secrets(secrets_path)

    #export_path = os.path.join(os.path.dirname(os.path.realpath(__file__)), "export/states")
    #upload(export_path, "0B03IIavLYTovdWg4NGtzSW9wb2c", " data", "LESO acquistion data for state of ")

    export_path = os.path.join(os.path.dirname(os.path.realpath(__file__)), "export/states/specific")
    upload(export_path, "0B03IIavLYToveDJsQ25zY0hVNkk", " agency-specific data", "Agency-by-agency LESO program acquistion data for state of ")

