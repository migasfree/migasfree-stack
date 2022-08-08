#!/usr/bin/python3

import os
import shutil
import fnmatch
import requests

from django.conf import settings
from migasfree.utils import get_secret, get_setting
from migasfree.core.pms import get_pms

SERVER_URL = f'http://{get_setting("MIGASFREE_FQDN")}'


def get_auth_token():
    return f'Token {get_secret("token_admin")}'


if __name__ == '__main__':
    locations = []
    package_sets = []

    for root, dirnames, filenames in os.walk(settings.MEDIA_ROOT):
        for filename in fnmatch.filter(dirnames, get_setting('MIGASFREE_STORE_TRAILING_PATH')):
            locations.append(os.path.join(root, filename))

    for location in locations:
        len_location = len(location.replace(settings.MEDIA_ROOT, '').split('/'))
        for root, dirnames, filenames in os.walk(location):
            for dirname in dirnames:
                for _root, _dir, _filenames in os.walk(os.path.join(location, dirname)):
                    len_candidate_set = len(_root.replace(settings.MEDIA_ROOT, '').split('/'))
                    if _filenames and not _dir and len_candidate_set - len_location > 1:
                        parts = _root.replace(settings.MEDIA_ROOT, '').split('/')
                        package_sets.append({
                            'location': _root,
                            'name': parts[-1],
                            'project': parts[1],
                            'store': parts[-2],
                            'packages': _filenames
                        })

    if len(package_sets) > 0:
        API_URL = f'{SERVER_URL}/api/v1/token'
        AUTH_TOKEN = get_auth_token()

        for item in package_sets:
            req = requests.get(
                f'{API_URL}/package-sets/',
                {
                    'name': item['name'],
                    'project__name__icontains': item['project'],
                    'store__name__icontains': item['store']
                },
                headers={'Authorization': AUTH_TOKEN}
            )

            response = req.json()
            if response['count'] == 1:
                package_set = response['results'][0]
                print(package_set)  # DEBUG

                files = []
                for package in item['packages']:
                    files.append(
                        (
                            'files',
                            (
                                package,
                                open(os.path.join(item['location'], package), 'rb'),
                                get_pms(package_set['project']['pms']).mimetypes[0]
                            )
                        )
                    )

                response = requests.patch(
                    f'/package-sets/{package_set["id"]}',
                    files=files
                )
                print(response.text)  # DEBUG
                print(response)  # DEBUG
