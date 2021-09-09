extends Node

# Time between 0.0 and 24.0
var time := 12.0 setget set_time, get_time

# Day within year between 0 and 365 (or 366)
var day := 0 setget set_day, get_day

# Year
var year := 2021 setget set_year, get_year

signal datetime_changed


func set_datetime(new_time, new_day, new_year):
	time = new_time
	day = new_day
	year = new_year
	emit_signal("datetime_changed")


func set_time(new_time):
	time = new_time
	emit_signal("datetime_changed")

func get_time():
	return time


func set_day(new_day):
	day = new_day
	emit_signal("datetime_changed")

func get_day():
	return day


func set_year(new_year):
	year = new_year
	emit_signal("datetime_changed")

func get_year():
	return year
