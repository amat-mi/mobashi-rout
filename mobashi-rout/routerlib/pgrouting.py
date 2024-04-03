from typing import List, Optional
from .mobashi_psycopgr import PGRouting, PgrNode
from routingpy.direction import Direction, Directions
from .factory import Router


class PGRoutingRouter(PGRouting, Router):

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        if self._conn is None:
            raise ValueError('Error connecting to: {}'.format(
                kwargs.get('dbname', None)))

    def directions(self, locations: List[List[float]], profile: str) -> Directions | Direction:
        self.set_meta_data(
            table=f'{profile}_ways',
        )
        # start node is the first location specified, end node is the last one
        # use -1 as id for start node and -2 for end node
        start_node = PgrNode(-1, locations[0][0], locations[0][1])
        end_node= PgrNode(-2, locations[-1][0], locations[-1][1])
        routes = super().get_routes(start_node, end_node)
        route = routes[start_node, end_node]
        #The geometry list in [[lon1, lat1], [lon2, lat2]]
        geometry = [[x.lon, x.lat] for x in route['path']]
        return Direction(
            geometry=geometry, 
            duration=route['cost'], 
            distance=None, 
            raw=route
        )

