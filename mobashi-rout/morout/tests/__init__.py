import os
import django
from django.apps import apps
from django.test.utils import setup_databases, setup_test_environment


if not apps.ready:
    os.environ.setdefault("DJANGO_SETTINGS_MODULE", "server.settings")
    django.setup()  # Normal Django setup

    setup_test_environment()  # This does a lot of stuff inside Django tests

    # The next one is very important: it creates test databases and changes settings.DATABASES to point to them
    # otherwise tests will run against live database.
    # NOOO!!! Don't need database now!!!
    # setup_databases(verbosity=1, interactive=False, keepdb=True)
