extends Spatial

export var max_rotation := 60.0

var time_manager: TimeManager setget set_time_manager


func set_time_manager(new_time_manager):
	time_manager = new_time_manager
	time_manager.connect("datetime_changed", self, "_on_datetime_changed")
	_on_datetime_changed(time_manager.date_time)


func _on_datetime_changed(time_day_year):
	var new_time = time_day_year.time
	var new_rotation = clamp((new_time - 12.0) * 10.0, -max_rotation, max_rotation)
	
	$"root/PV-Tracker".rotation_degrees.z = new_rotation
