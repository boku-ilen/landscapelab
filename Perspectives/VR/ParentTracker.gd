extends Node

#
# Saves position and look direction data of the parent node.
# The parent must be a Spatial or derived.
#

onready var tracking_timer = get_node("TrackingTimer")

var file = File.new()


func _ready():
	# TODO: Do this when a new tracking session starts and add the session_id
	#  to the filename
	open_tracking_file("user://tracking1.csv")
	
	tracking_timer.connect("timeout", self, "write_to_tracking_file")


func get_look_direction():
	return get_parent().global_transform.basis.get_euler()


func get_position():
	return get_parent().global_transform.origin


func open_tracking_file(filename):
	if file.open(filename, File.WRITE) != 0:
		logger.error("Couldn't open tracking file!")
		return
	
	var line = PoolStringArray()
	
	line.append("Time")
	
	line.append("Position x")
	line.append("Position y")
	line.append("Position z")
	
	line.append("Pitch")
	line.append("Yaw")
	line.append("Roll")
	
	file.store_csv_line(line)


func write_to_tracking_file():
	var time = str(OS.get_system_time_msecs())
	var line = PoolStringArray()
	var pos = get_position()
	var look = get_look_direction()
	
	line.append(time)
	
	line.append(pos.x)
	line.append(pos.y)
	line.append(pos.z)
	
	line.append(rad2deg(look.x))
	line.append(rad2deg(look.y))
	line.append(rad2deg(look.z))
	
	file.store_csv_line(line)
