extends Node
class_name TimeManager


# Dictionary according to Godot's Time class:
# Contains year, month, day, hour, minute, second
var datetime = {
	"year": 2023,
	"month": 3,
	"day": 21,
	"hour": 11,
	"minute": 5,
	"second": 0
}

signal datetime_changed(new_datetime)
signal daytime_changed(is_day)


func set_datetime_by_dict(date):
	datetime = date


func set_date(year, month, day):
	var new_datetime = {
		"year": year,
		"month": month,
		"day": day,
		"hour": datetime["hour"],
		"minute": datetime["minute"],
		"second": datetime["second"]
	}
	
	_update_datetime(new_datetime)


func set_time(hour, minute, second=0):
	var new_datetime = {
		"year": datetime["year"],
		"month": datetime["month"],
		"day": datetime["day"],
		"hour": hour,
		"minute": minute,
		"second": second
	}
	
	_update_datetime(new_datetime)


func _update_datetime(new_datetime):
	var previous_is_nighttime = is_nighttime()
	
	datetime = new_datetime
	
	var new_is_nighttime = is_nighttime()
	
	datetime_changed.emit(datetime)
	
	if previous_is_nighttime and not new_is_nighttime:
		emit_signal("daytime_changed", true)
	elif new_is_nighttime and not previous_is_nighttime:
		emit_signal("daytime_changed", false)


func is_nighttime():
	# TODO: Consider a more sophisticated check
	return datetime["hour"] < 8 or datetime["hour"] > 19


func is_daytime():
	return not is_nighttime()
