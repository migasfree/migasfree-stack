import os


def get_secret_pass():
    password = ''
    with open('/run/secrets/password_database', 'r') as f:
        password = f.read()

    return password


DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql_psycopg2',
        'NAME': os.environ['POSTGRES_DB'],
        'USER': os.environ['POSTGRES_USER'],
        'PASSWORD': get_secret_pass(),
        'HOST': os.environ['POSTGRES_HOST'],
        'PORT': os.environ['POSTGRES_PORT'],
    }
}

LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '%(levelname)s %(asctime)s %(module)s %(process)d %(thread)d %(message)s'
        },
        'simple': {
            'format': '%(levelname)s %(message)s'
        },
    },
    'handlers': {
        'file': {
            'level': 'DEBUG',
            'class': 'logging.FileHandler',
            'filename': '/tmp/migasfree.log',
            'formatter': 'verbose',
        },
        'console': {
            'level': 'DEBUG',
            'class': 'logging.StreamHandler',
            'formatter': 'verbose',
        },
    },
    'loggers': {
        'migasfree': {
            'handlers': ['console', 'file'],
            'level': 'DEBUG',
        }
    },
    'root': {
        'level': 'INFO',
        'handlers': ['console', 'file']
    },
}

# DATASTORE
# =========
REDIS_HOST = 'datastore'
REDIS_PORT = 6379
REDIS_DB = 0
BROKER_URL = 'redis://%s:%d/%d' % (REDIS_HOST, REDIS_PORT, REDIS_DB)
CELERY_BROKER_URL = BROKER_URL
CELERY_RESULT_BACKEND = BROKER_URL
CACHES = {
    'default': {
        'BACKEND': 'django_redis.cache.RedisCache',
        'LOCATION': BROKER_URL,
        'OPTIONS': {
            'CLIENT_CLASS': 'django_redis.client.DefaultClient',
        }
    }
}

CHANNEL_LAYERS = {
    'default': {
        'BACKEND': 'channels_redis.core.RedisChannelLayer',
        'CONFIG': {
            'hosts': [(REDIS_HOST, REDIS_PORT)]
        }
    }
}

# NECESSARY FOR SWAGGER AND REST-FRAMEWORK
# Setup support for proxy headers
# SWAGGER_SETTINGS['DEFAULT_INFO'] = 'import.path.to.urls.api_info'
USE_X_FORWARDED_HOST = True
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')

DEBUG = False

# e-mail config
EMAIL_USE_TLS = True
EMAIL_HOST = 'webmail.mydomain.es'
EMAIL_PORT = 25
EMAIL_HOST_USER = "myuser"
EMAIL_HOST_PASSWORD = ""
DEFAULT_FROM_EMAIL = "migasfree-server <noreply@mydomain.es>"
ADMINS = [('mymame', 'myuser@mydomain.es'),]

MEDIA_URL ="/public/"
MIGASFREE_TMP_DIR = '/var/tmp'
MIGASFREE_SECRET_DIR = '/var/run/secrets'

MIGASFREE_EXTERNAL_ACTIONS = {
    "computer": {
        "ping": {"title": "PING", "description": "check connectivity"},
        "ssh": {"title": "SSH", "description": "remote control via ssh"},
        "vnc": {"title": "VNC", "description": "remote control vnc", "many": False},
        "sync": {"title": "SYNC", "description": "ssh -> run migasfree -u"},
        "install": {
            "title": "INSTALL",
            "description": "ssh -> install a package",
            "related": ["deployment", "computer"]
        },
    },
    "error": {
        "clean": {"title": "delete", "description": "delete errors"},
    }
}

MIGASFREE_ORGANIZATION = "ACME"
MIGASFREE_HELP_DESK = "Help Desk: 555 555 555"
# MIGASFREE_COMPUTER_SEARCH_FIELDS = ('name', 'id', 'ip_address', 'forwarded_ip_address')

# Important!!!
SESSION_COOKIE_AGE = 1

CORS_ORIGIN_ALLOW_ALL = True
ALLOWED_HOSTS = ['*']

# Uncomment and fill with FQDN value
# CSRF_TRUSTED_ORIGINS = ['http or https://fill_FQDN_value']
