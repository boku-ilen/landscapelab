from godot import exposed, export
from godot import *

from PIL import Image
from PIL.ExifTags import TAGS
from PIL.ExifTags import GPSTAGS


@exposed
class ExifInterface(Node):
	
	geotags = {}
	
	def open(self, filename):
		image = Image.open(str(filename))
		image.verify()
		
		exif = image._getexif()
		
		for (idx, tag) in TAGS.items():
			if tag == 'GPSInfo':
				if idx not in exif:
					raise ValueError("No EXIF geotags found")
				
				for (key, val) in GPSTAGS.items():
					if key in exif[idx]:
						self.geotags[val] = exif[idx][key]
	
	def get_decimal_from_dms(self, dms, ref):
		degrees = dms[0]
		minutes = dms[1] / 60.0
		seconds = dms[2] / 3600.0

		if ref in ['S', 'W']:
			degrees = -degrees
			minutes = -minutes
			seconds = -seconds

		return round(degrees + minutes + seconds, 5)

	def get_coordinates(self):
		lat = self.get_decimal_from_dms(self.geotags['GPSLatitude'], self.geotags['GPSLatitudeRef'])
		lon = self.get_decimal_from_dms(self.geotags['GPSLongitude'], self.geotags['GPSLongitudeRef'])

		return Vector2(lat, lon)
