# Database
# https://docs.djangoproject.com/en/4.2/ref/settings/#databases

import os

with open(os.path.abspath(os.path.join(os.path.dirname(__file__),
                                       os.getenv('DJANGO_DATABASE_PASSWORD_FILE')))) as f:
    DJANGO_DATABASE_PASSWORD = f.read().strip()

DATABASES = {
    "default": {
        'ENGINE': 'django.contrib.gis.db.backends.postgis',
        'NAME': os.getenv('DJANGO_DATABASE_NAME'),
        'USER': os.getenv('DJANGO_DATABASE_USER'),
        'PASSWORD': DJANGO_DATABASE_PASSWORD,
        'HOST': 'db',  # use service name from docker-compose.yml
        'PORT': '5432',  # MUST use the "internal" service port, not the published one!!!
    },
    "milano": {
        'ENGINE': 'django.contrib.gis.db.backends.postgis',
        'NAME': 'milano',
        'USER': 'django',
        'PASSWORD': DJANGO_DATABASE_PASSWORD,
        'HOST': 'host.docker.internal',  # address of Docker Host machine
        'PORT': '5433',  # port on the Docker Host machine
    }
}
