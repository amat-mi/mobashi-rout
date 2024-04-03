import inspect
import importlib
from abc import abstractmethod
from dataclasses import dataclass, field
from typing import List, Optional, Type
from routingpy.routers import get_router_by_name
from routingpy.direction import Direction, Directions
from routingpy.exceptions import RouterNotFound


class Router:
    @abstractmethod
    def directions(
            self,
            locations: List[List[float]],
            profile: str) -> (Directions | Direction):
        pass


@ dataclass
class RouterServiceConfig:
    name: str
    router_name: str
    options: dict = field(default_factory=dict)
    attributes: dict = field(default_factory=dict)


@ dataclass
class RouterService:
    config: RouterServiceConfig
    router_class: Type[Router]
    router: Router = None


def get_local_router_by_name(name: str) -> Router:
    try:
        module = importlib.import_module(f'.{name}', package=__package__)
        classes = inspect.getmembers(module, inspect.isclass)
        # Get a list of all classes in the module that are defined in the module itself
        classes = [m for m in inspect.getmembers(
            module, inspect.isclass) if m[1].__module__ == module.__name__]
        if classes:
            return classes[0][1]
        raise ModuleNotFoundError()
    except ModuleNotFoundError:
        raise RouterNotFound()


class RouterFactory:
    services: dict[str, RouterService] = {}

    def __init__(self, configs: list[RouterServiceConfig | dict] = None):
        self.set_services(configs)

    def set_services(self, configs: list[RouterServiceConfig | dict]) -> None:
        if not configs:
            return
        i = 0
        for config in configs:
            try:
                self.add_service(config)
            except Exception as e:
                raise ValueError(f'Error in config {i} => {e}')
            i += 1

    def add_service(self, config: RouterServiceConfig | dict) -> RouterService:
        if not config:
            return None
        if isinstance(config, dict):
            config = RouterServiceConfig(**config)
        if not config.name:
            raise ValueError(f'Missing name')
        try:
            router_name = (config.router_name or '').lower()
            if router_name.startswith('local_'):
                router_class = get_local_router_by_name(
                    router_name.removeprefix('local_'))
            else:
                router_class = get_router_by_name(router_name)
            service = RouterService(config, router_class)
            self.services[service.config.name] = service
            return service
        except RouterNotFound as e:
            raise ValueError(
                f'Invalid router_name: {config.router_name}')

    def get_service(self, name: str) -> RouterService:
        try:
            res = self.services[name]
        except KeyError:
            raise ValueError(
                f'Invalid service name: {name}')
        if res.router is None:
            res.router = res.router_class(**res.config.options)
            for k, v in (res.config.attributes or {}).items():
                setattr(res.router, k, v)
        return res
