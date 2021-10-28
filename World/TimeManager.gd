extends Node
class_name TimeManager


var date_time = DateTime.new()

signal datetime_changed(time_day_yer)

class DateTime:
	# Time between 0.0 and 24.0
	var time := 12.0
	# Day within year between 0 and 365 (or 366)
	var day := 0
	# Year
	var year := 2021


func set_datetime(new_time, new_day, new_year):
	date_time.time = new_time
	date_time.day = new_day
	date_time.year = new_year
	emit_signal("datetime_changed", date_time)


func set_time(new_time):
	date_time.time = new_time
	emit_signal("datetime_changed", date_time)

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
