from typing import List, Optional
from .mobashi_pgrksp import PGRKSPRouting
from routingpy.direction import Direction, Directions
from .factory import Router


class PGRKSPRouter(PGRKSPRouting, Router):

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

    def directions(self, locations: List[List[float]], profile: str) -> Directions | Direction:
        self.set_meta_data(
            mode=profile,
            k=1
        )
        route = super().get_route(locations)
        #The geometry should be constructed by joining all returned geometries by the "ord" field
        geometry = None
        #Total dist and time should be constructed by summing values form all returned records
        trav_dist = None
        trav_time = None
        return Direction(
            geometry=geometry, 
            distance=trav_dist, 
            duration=trav_time,
            raw=route
        )

