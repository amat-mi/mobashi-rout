from dataclasses import dataclass, field
from typing import Type
from geopy.geocoders import get_geocoder_for_service
from geopy.exc import GeocoderNotFound
from geopy.geocoders.base import Geocoder


@dataclass
class GeocoderServiceConfig:
    name: str
    geocoder_name: str
    options: dict = field(default_factory=dict)
    attributes: dict = field(default_factory=dict)


@dataclass
class GeocoderService:
    config: GeocoderServiceConfig
    geocoder_class: Type[Geocoder]
    geocoder: Geocoder = None


class GeocoderFactory:
    services: dict[str, GeocoderService] = {}

    def __init__(self, configs: list[GeocoderServiceConfig | dict] = None):
        self.set_services(configs)

    def set_services(self, configs: list[GeocoderServiceConfig | dict]) -> None:
        if not configs:
            return
        i = 0
        for config in configs:
            try:
                self.add_service(config)
            except Exception as e:
                raise ValueError(f'Error in config {i} => {e}')
            i += 1

    def add_service(self, config: GeocoderServiceConfig | dict) -> GeocoderService:
        if not config:
            return None
        if isinstance(config, dict):
            config = GeocoderServiceConfig(**config)
        if not config.name:
            raise ValueError(f'Missing name')
        try:
            geocoder_class = get_geocoder_for_service(
                (config.geocoder_name or '').lower())
            service = GeocoderService(config, geocoder_class)
            self.services[service.config.name] = service
            return service
        except GeocoderNotFound as e:
            raise ValueError(
                f'Invalid geocoder_name: {config.geocoder_name}')

    def get_service(self, name: str) -> GeocoderService:
        try:
            res = self.services[name]
        except KeyError:
            raise ValueError(
                f'Invalid service name: {name}')
        if res.geocoder is None:
            res.geocoder = res.geocoder_class(**res.config.options)
            for k, v in (res.config.attributes or {}).items():
                setattr(res.geocoder, k, v)
        return res
