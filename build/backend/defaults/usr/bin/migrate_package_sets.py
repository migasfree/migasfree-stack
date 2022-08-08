#!/usr/bin/python3

import os
import shutil
import fnmatch
import requests

from django.conf import settings
from migasfree.utils import get_secret, get_setting

SERVER_URL = f'http://{get_setting("MIGASFREE_FQDN")}'


def get_auth_token():
    return f'Token {get_secret("token_admin")}'


if __name__ == '__main__':
    locations = []
    package_sets = []

    for root, dirnames, filenames in os.walk(settings.MEDIA_ROOT):
        for filename in fnmatch.filter(dirnames, 'stores'):
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
        print(get_setting('MIGASFREE_SECRET_DIR'))

        for item in package_sets:
            print(item)
