extends Node

#
# Saves position and look direction data of the parent node.
# The parent must be a Spatial or derived.
#

var version = Settings.get_setting("meta", "version")
var usage = Settings.get_setting("meta", "usage")

onready var position_tracking_timer = get_node("PositionTrackingTimer")
onready var screenshot_timer = get_node("ScreenshotTimer")

var file = File.new()

const LOG_MODULE := "PERSPECTIVES"


# Start saving data with the current Session id
func start_tracking(additional_flag: String = ""):
	var filename
	
	# FIXME: we need some kind of session ID here
	if additional_flag == "":
		filename = "user://tracking-%s-%s-session%d.csv" % [usage, version, 0] #[usage, version, Session.session_id]
	else:
		filename = "user://tracking-%s-%s-session%d-%s.csv" % [usage, version, 0, additional_flag] #[usage, version, "Session.session_id", additional_flag]
	
	open_tracking_file(filename)
	
	screenshot_timer.connect("timeout", self, "take_screenshot")


# Start or stop tracking depending on the Session id
func toggle_pause_tracking():
	# FIXME: Replace "true" with a pendant to "Session.session_id > 0"
	# FIXME: What is this for in the first place?
	if true:
		start_tracking()
	else:
		stop_tracking()


# Stop saving data
func stop_tracking():
	close_tracking_file()
	screenshot_timer.disconnect("timeout", self, "take_screenshot")


func get_look_direction():
	return get_parent().global_transform.basis.get_euler()


func get_position():
	return get_parent().global_transform.origin


# Prepare for tracking: Open / create the CSV file and connect the timer to it
func open_tracking_file(filename):
	if file.open(filename, File.WRITE) != 0:
		logger.error("Couldn't open tracking file!", LOG_MODULE)
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
	
	position_tracking_timer.connect("timeout", self, "write_to_tracking_file")


# Close the CSV file and stop saving data into it
func close_tracking_file():
	file.close()
	
	position_tracking_timer.disconnect("timeout", self, "write_to_tracking_file")


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


func take_screenshot():
	# Retrieve the captured image
	var img = get_viewport().get_texture().get_data()
  
	# Flip it on the y-axis (because it's flipped)
	img.flip_y()
	
	# Save to a file, use the current time for naming
	var timestamp = OS.get_datetime()
	# FIXME: Replace with a pendant to "Session"
	var screenshot_filename = "user://screenshot-%d%d%d-%d%d%d-%d.png" % [timestamp["year"], timestamp["month"],
	 timestamp["day"], timestamp["hour"], timestamp["minute"], timestamp["second"], 0]#"Session.session_id"]
	
	# Medium to low priority - we do want it to save sometime soon, but doesn't have to be immediate
	ThreadPool.enqueue_task(ThreadPool.Task.new(self, "_save_screenshot", [img, screenshot_filename]), 15)


# Actually save a screenshot - to be run in a thread
func _save_screenshot(img_filename_array):
	img_filename_array[0].save_png(img_filename_array[1])
	logger.info("captured screenshot in %s " % [img_filename_array[1]], LOG_MODULE)
	
