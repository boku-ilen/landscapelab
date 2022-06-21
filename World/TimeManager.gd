extends Node
class_name TimeManager


var date_time = DateTime.new()

signal datetime_changed(time_day_yer)
signal daytime_changed(is_day) # true if changed to day, false if changed to night

class DateTime:
	# Time between 0.0 and 24.0
	var time := 12.0
	# Day within year between 0 and 365 (or 366)
	var day := 0
	# Year
	var year := 2021


func set_datetime(new_time, new_day, new_year):
	set_time(new_time)
	date_time.day = new_day
	date_time.year = new_year
	emit_signal("datetime_changed", date_time)


func set_datetime_by_class(datetime: DateTime):
	date_time = datetime
	emit_signal("datetime_changed", date_time)


func set_time(new_time):
	var previous_time = date_time.time
	
	date_time.time = new_time
	emit_signal("datetime_changed", date_time)
	
	if _is_nighttime(previous_time) and not _is_nighttime(new_time):
		emit_signal("daytime_changed", true)
	elif _is_nighttime(new_time) and not _is_nighttime(previous_time):
		emit_signal("daytime_changed", false)


func _is_nighttime(time):
	# TODO: Consider a more sophisticated check
	return time < 8.0 or time > 20.0


func is_daytime():
	return not _is_nighttime(date_time.time)


func get_time():
	return date_time.time


func set_day(new_day):
	date_time.day = new_day
	emit_signal("datetime_changed", date_time)

func get_day():
	return date_time.day


func set_year(new_year):
	date_time.year = new_year
	emit_signal("datetime_changed", date_time)

func get_year():
	return date_time.year
