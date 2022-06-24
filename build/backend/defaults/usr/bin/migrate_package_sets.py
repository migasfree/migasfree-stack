#!/usr/bin/python3

import os
import shutil
import fnmatch

from django.conf import settings


if __name__ == '__main__':
    locations = []
    for root, dirnames, filenames in os.walk(settings.MEDIA_ROOT):
        for filename in fnmatch.filter(dirnames, 'stores'):
            locations.append(os.path.join(root, filename))

    for location in locations:
        for root, dirnames, filenames in os.walk(location):
            for dirname in dirnames:
                print(dirname, filenames)
