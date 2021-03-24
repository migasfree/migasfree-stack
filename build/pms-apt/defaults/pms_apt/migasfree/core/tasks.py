#!/usr/bin/env python3
# -*- coding: UTF-8 -*-

import os
import sys
import shutil
import redis
import requests
import json
import shutil

from celery import Celery

from api import ApiToken


BROKER_URL='redis://datastore:6379/1'    
BACKEND=BROKER_URL

_USER = 'admin'  # User admin in backend
_SERVER = 'backend:8080'

_PATH_PUBLIC=os.environ["PATH_PUBLIC"]
_REPOSITORY_TRAILING_PATH='repos'
_STORE_TRAILING_PATH="stores"


app = Celery('apt_tasks', broker=BROKER_URL,  backend=BACKEND)
con=redis.Redis(host='datastore', port=6379, db=0)


def get_secret_pass():
    password = ""
    with open("/run/secrets/password_backend","r") as f:
        password = f.read()
    return password

def get_token(user):
    token=''
    data = {'username': 'admin', 'password': get_secret_pass()}
    r = requests.post(
        '{0}://{1}/token-auth/'.format('http', _SERVER ),
        headers={'content-type': 'application/json'},
        data=json.dumps(data),
        proxies={'http': '', 'https': ''}
    )
    if r.status_code == 200:
        token= r.json()['token']
    else:
        print('Error to get token: {}'.format( r.status_code) )
    return token


api = ApiToken(server=_SERVER, user=_USER, token=get_token(_USER))
api.protocol="http"


@app.task
def create_repository_metadata(deployment_id):

    deployment = api.get("deployments/{}".format(deployment_id), {})
    project = api.get("projects", {"id": deployment["project"]["id"]} )

    # ADD NOTIFY IN REDIS
    con.hmset(
        'migasfree:repos:%d' % deployment_id, {
            'name': deployment["name"],
            'project': project["name"]
        }
    )
    con.sadd('migasfree:watch:repos', deployment_id)
    
    _repository_path = "%s/%s/%s/dists/%s" % (_PATH_PUBLIC, project["name"], _REPOSITORY_TRAILING_PATH, deployment["name"])
    _stores_path ="../../../../%s" % (_STORE_TRAILING_PATH) # relative
    _tmp_path = "%s/%s/TMP/dists/%s" % (_PATH_PUBLIC, project["name"], deployment["name"])
    _pkg_tmp_path = os.path.join(
        _tmp_path,
        'PKGS'  # FIXME hardcoded path!!!
    )

    if not os.path.exists(_pkg_tmp_path):
        os.makedirs(_pkg_tmp_path)

    # Links in TMP (TODO: hacer relativa la ruta)
    for package in deployment["available_packages"]:
        package_name = package["fullname"]
        store_name = api.get("packages", {"id": package["id"]} )["store"]["name"]
        _dst = os.path.join(_pkg_tmp_path, package_name)
        if not os.path.lexists(_dst):
            os.symlink(
                os.path.join(_stores_path, store_name, package_name),
                _dst
            )
    # Metadata in TMP
    os.system('/usr/bin/repository-metadata "%s" "%s" ' % ( project["name"], deployment["name"]))

    # Move from TMP to REPOSITORY
    shutil.rmtree(_repository_path, ignore_errors=True)
    shutil.copytree(_tmp_path, _repository_path, symlinks=True)
    shutil.rmtree(_tmp_path)

   # REMOVE NOTIFY IN REDIS
    con.hdel('migasfree:repos:%d' % deployment_id, '*')
    con.srem('migasfree:watch:repos', deployment_id)


@app.task
def remove_repository_metadata(deployment_id, old_slug=''):
    deployment = api.get("deployments", {"id": deployment_id} )
    project = api.get("projects", {"id": deployment["project"]["id"]} )

    if old_slug:
        slug = old_slug
    else:
        slug = deployment["slug"]

    _PATH_DEPLOYMENT= os.path.join(
        _PATH_PUBLIC,
        project["name"],
        _REPOSITORY_TRAILING_PATH,
        'dists',
        slug
        )
    shutil.rmtree(_PATH_DEPLOYMENT, ignore_errors=True)