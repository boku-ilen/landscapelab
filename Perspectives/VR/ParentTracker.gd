extends Node

#
# Saves position and look direction data of the parent node.
# The parent must be a Spatial or derived.
#

onready var tracking_timer = get_node("TrackingTimer")

var file = File.new()


func _ready():
	# Connect these signals in CONNECT_DEFERRED so that we have the new session_id by then
	GlobalSignal.connect("tracking_start", self, "start_tracking", [], CONNECT_DEFERRED)
	GlobalSignal.connect("tracking_pause", self, "toggle_pause_tracking", [], CONNECT_DEFERRED)
	GlobalSignal.connect("tracking_stop", self, "stop_tracking", [], CONNECT_DEFERRED)


# Start saving data with the current Session id
func start_tracking():
	var filename = "user://tracking%d.csv" % [Session.session_id]
	
	open_tracking_file(filename)


# Start or stop tracking depending on the Session id
func toggle_pause_tracking():
	if Session.session_id > 0:
		start_tracking()
	else:
		close_tracking_file()


# Stop saving data
func stop_tracking():
	close_tracking_file()


func get_look_direction():
	return get_parent().global_transform.basis.get_euler()


func get_position():
	return get_parent().global_transform.origin


# Prepare for tracking: Open / create the CSV file and connect the timer to it
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
	
	tracking_timer.connect("timeout", self, "write_to_tracking_file")


# Close the CSV file and stop saving data into it
func close_tracking_file():
	file.close()
	
	tracking_timer.disconnect("timeout", self, "write_to_tracking_file")


# Write a line of tracking data into the CSV
func write_to_tracking_file():
	var time = str(OS.get_system_time_msecs())
	var pos = get_position()
	var look = get_look_direction()
	
	var line = PoolStringArray()
	
	line.append(time)
	
	line.append(pos.x)
	line.append(pos.y)
	line.append(pos.z)
	
	line.append(rad2deg(look.x))
	line.append(rad2deg(look.y))
	line.append(rad2deg(look.z))
	
	file.store_csv_line(line)
