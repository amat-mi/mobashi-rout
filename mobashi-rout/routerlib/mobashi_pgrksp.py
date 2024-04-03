from typing import List
from django.db import connections


class PGRKSPRouting(object):
    _meta_data = {
        'mode': 'car',
        'k': 1
    }

    def __init__(self, *args, **kwargs):
        self.dbalias = kwargs.get('dbalias')

    def set_meta_data(self, **kwargs):
        """Set meta data of tables if it is different from the default."""
        for k, v in kwargs.items():
            if k not in self._meta_data.keys():
                raise ValueError("set_meta_data: invaid key {}".format(k))
            if not isinstance(v, (str, bool, int)):
                raise ValueError("set_meta_data: invalid value {}".format(v))
            self._meta_data.update({k: v})
        return self._meta_data

    def get_route(self, locations: List[List[float]]):
        with connections[self.dbalias].cursor() as cursor:
            sql = f"select * from elab.routing_{self._meta_data['mode']}(%s, %s, %s, %s, %s)"
            cursor.execute(sql, [
                locations[0][1],  # lat_from
                locations[0][0],  # lng_from
                locations[1][1],  # lat_to
                locations[1][0],  # lng_to
                self._meta_data['k']
            ])
            return cursor.fetchall()
