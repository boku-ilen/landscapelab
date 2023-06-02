extends Node3D

@export var max_rotation := 60.0

var time_manager: TimeManager :
	get:
		return time_manager
	set(new_time_manager):
		time_manager = new_time_manager
		time_manager.datetime_changed.connect(_on_datetime_changed)
		_on_datetime_changed(time_manager.datetime)


func _on_datetime_changed(time_day_year):
	var new_time = time_day_year.hour
	var new_rotation = clamp((new_time - 12.0) * 10.0, -max_rotation, max_rotation)
	
	$"root/PV-Tracker".rotation.z = deg_to_rad(new_rotation)
