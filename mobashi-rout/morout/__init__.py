from django.conf import settings
from geocoderlib.factory import GeocoderFactory
from routerlib.factory import RouterFactory


# global geocoders factory object,
# configured from "MOBASHI_GEOCODERS.SERVICES" settings variable
GEOCODERS = GeocoderFactory(settings.MOBASHI_GEOCODERS["SERVICES"])

# global routers factory object,
# configured from "MOBASHI_ROUTERS.SERVICES" settings variable
ROUTERS = RouterFactory(settings.MOBASHI_ROUTERS["SERVICES"])
