from decimal import Decimal
import base64
from urllib.parse import unquote_plus
from django.http import HttpResponseBadRequest
from rest_framework.views import APIView
from rest_framework.response import Response
from . import GEOCODERS, ROUTERS


class QueryParameterMixin:
    def get_query_parameter(self, request, query_name='query'):
        query_encoded = request.GET.get(query_name, '')
        try:
            # base64url decode
            padding = '=' * (4 - (len(query_encoded) % 4))
            query = base64.urlsafe_b64decode(query_encoded + padding).decode()
        except Exception as e:
            try:
                query = unquote_plus(query_encoded)
            except Exception as e:
                return None
        return query


class LocationParameterMixin:
    def get_location_parameter(self, request, lat_name='lat', lng_name='lng'):
        lat_str = request.GET.get(lat_name, '')
        lng_str = request.GET.get(lng_name, '')
        try:
            lat = float(Decimal(lat_str))
            lng = float(Decimal(lng_str))
        except Exception as e:
            return None, None
        return lat, lng


class GeocodeView(QueryParameterMixin, APIView):
    def get(self, request, format=None):
        query = self.get_query_parameter(request)
        if not query:
            return Response({
                "error": "Invalid query parameter. It must be a base64url or url encoded string."
            }, status=HttpResponseBadRequest.status_code)
        service_name = request.GET.get('service', 'nominatim')
        service = GEOCODERS.get_service(service_name)
        # WARN!!! For geocoders, order of coordinates is latitude/longitude!!!
        res = service.geocoder.geocode(query)
        return Response({
            "query": query,
            "result": res.raw
        })


class ReverseView(LocationParameterMixin, APIView):
    def get(self, request, format=None):
        lat, lng = self.get_location_parameter(request)
        if lat is None or lng is None:
            return Response({
                "error": "Invalid lat or lng parameter. They must be decimal numbers."
            }, status=HttpResponseBadRequest.status_code)
        service_name = request.GET.get('service', 'nominatim')
        service = GEOCODERS.get_service(service_name)
        # WARN!!! For geocoders, order of coordinates is latitude/longitude!!!
        res = service.geocoder.reverse((lat, lng))
        return Response({
            "lat": lat,
            "lng": lng,
            "result": res.raw
        })


class DirectionsView(LocationParameterMixin, APIView):
    def get(self, request, format=None):
        lat_from, lng_from = self.get_location_parameter(
            request, lat_name='lat_from', lng_name='lng_from')
        lat_to, lng_to = self.get_location_parameter(
            request, lat_name='lat_to', lng_name='lng_to')
        if lat_from is None or lng_from is None:
            return Response({
                "error": "Invalid lat_from or lng_from parameter. They must be decimal numbers."
            }, status=HttpResponseBadRequest.status_code)
        if lat_to is None or lng_to is None:
            return Response({
                "error": "Invalid lat_to or lng_to parameter. They must be decimal numbers."
            }, status=HttpResponseBadRequest.status_code)
        service_name = request.GET.get('service', 'ors')
        service = ROUTERS.get_service(service_name)
        profile = request.GET.get('profile', 'driving-car')
        # WARN!!! For routers, order of coordinates is longitude/latitude!!!
        res = service.router.directions(
            [[lng_from, lat_from], [lng_to, lat_to]], profile)
        return Response({
            "lat_from": lat_from,
            "lng_from": lng_from,
            "lat_to": lat_to,
            "lng_to": lng_to,
            "result": res.raw
        })
