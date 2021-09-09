from godot import exposed, export
from godot import *

import datetime
from pysolar.solar import *
from dateutil import tz


@exposed
class PysolarInterface(Node):
	def get_sun_altitude_azimuth(self, lat, lon, time, day, year):
		"""
		Returns an array with the altitude and the azimuth of the sun at the
		given position and time.
		"""
		CET = tz.gettz("CET")
		
		datetime_object = datetime.datetime(year, 1, 1, tzinfo=CET) \
				+ datetime.timedelta(days=day, hours=time)
		
		return Array([get_altitude(lat, lon, datetime_object),
				get_azimuth(lat, lon, datetime_object)])
