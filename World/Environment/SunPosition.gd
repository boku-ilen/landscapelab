extends Object
class_name SunPosition

# Helper class for calculating the sun's altitude and azimuth from a given datetime and position.
# Adapted from the Python library suncalc: https://github.com/kylebarron/suncalc-py

const DAY_MS: float = 1000 * 60 * 60 * 24
const J1970: float = 2440588
const J2000: float = 2451545

const e: float = rad * 23.4397
const rad: float = PI / 180


# datetime is a dictionary according to https://docs.godotengine.org/en/stable/classes/class_time.html
# contains `year`, `month`, `day`, `hour`, `minute`, `second`; in UTC timezone!
# azimuth is the angle of the sun from north (something like 90° in the morning, 180° at midday, 270° in the evening)
# altitude is the angle of the sun from the horizon (0° in the morning and evening, 180° at perfect midday)
static func get_solar_angles_for_datetime(datetime, lat: float, lon: float) -> Dictionary:
	var lw = rad * -lon
	var phi = rad * lat

	# Julian Day of the given datetime
	var JD = (Time.get_unix_time_from_datetime_dict(datetime) * 1000.0) / DAY_MS - 0.5 + J1970 - J2000
	
	# Ecliptic Longitude
	var M = rad * (357.5291 + 0.98560028 * JD)
	var L = M + rad * (1.9148 * sin(M) + 0.02 * sin(2.0 * M) + 0.0003 * sin(3.0 * M)) + rad * 102.9372 + PI
	
	# Declination and right ascension
	var declination = asin(sin(0.0) * cos(e) + cos(0.0) * sin(e) * sin(L))
	var right_ascension = atan2(tan(sin(L) * cos(e) - tan(0.0) * sin(e)), cos(L))

	var H = rad * (280.16 + 360.9856235 * JD) - lw - right_ascension

	return {
		"altitude": rad_to_deg(asin(sin(phi) * sin(declination) + cos(phi) * cos(declination) * cos(H))),
		"azimuth": 180.0 + rad_to_deg(atan2(sin(H), cos(H) * sin(phi) - tan(declination) * cos(phi)))
	}
