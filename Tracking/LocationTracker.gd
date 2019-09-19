extends Spatial

var interval = Settings.get_setting("tracking", "interval", 1)  # in seconds 
var timer


# initialize the internal timer but don't start it yet
func _ready():
	
	# register the ui signals to start/pause/stop the tracking
	GlobalSignal.connect("tracking_start", self, "start_tracking")
	GlobalSignal.connect("tracking_pause", self, "toggle_pause_tracking")
	GlobalSignal.connect("tracking_stop", self, "stop_tracking")
	
	# initialize the timer for frequently sending location and storing screenshot
	timer = Timer.new()
	timer.set_one_shot(false)
	timer.set_timer_process_mode(0)
	timer.set_wait_time(interval)
	timer.set_autostart(false)
	timer.connect("timeout", self, "send_position")
	timer.connect("timeout", self, "make_screenshot")
	self.add_child(timer)


# we are starting the tracking - it is called by the play button
func start_tracking():
	
	# get a new session from server if the session_id is invalid
	if Session.session_id < 0:
		Session.start_session(Session.scenario_id)
		logger.info("starting tracking with new session id: %s" % [Session.session_id])
	else:
		logger.info("restarting paused tracking with session id: %s" % [Session.session_id])
	
	# start the timer
	timer.start()


func pause_tracking():
	timer.stop()
	logger.info("pausing tracking with session id: %s" % [Session.session_id])


# this function stops the tracking - it is called by the stop button
func stop_tracking():
	pause_tracking()
	logger.info("stopping tracking and invalidating session id: %s" % [Session.scenario_id])
	Session.session_id = -1  # flag the session as invalid


# Make a screenshot and save it in a thread
# https://github.com/godotengine/godot-demo-projects/blob/master/viewport/screen_capture/screen_capture.gd
func make_screenshot():
	# Retrieve the captured image
	var img = get_viewport().get_texture().get_data()
  
	# Flip it on the y-axis (because it's flipped)
	img.flip_y()
	
	# Save to a file, use the current time for naming
	var timestamp = OS.get_datetime()
	var screenshot_filename = "user://screenshot-%d%d%d-%d%d%d-%d.png" % [timestamp["year"], timestamp["month"],
	 timestamp["day"], timestamp["hour"], timestamp["minute"], timestamp["second"], Session.session_id]
	
	# Medium to low priority - we do want it to save sometime soon, but doesn't have to be immediate
	ThreadPool.enqueue_task(ThreadPool.Task.new(self, "save_screenshot", [img, screenshot_filename]), 15)


# Actually save a screenshot - to be run in a thread
func save_screenshot(img_filename_array):
	img_filename_array[0].save_png(img_filename_array[1])
	logger.info("captured screenshot in %s " % [img_filename_array[1]])


# Send the current player position to the server
func send_position():
	# We get the current player position here and do the request in a thread in order
	#  to get the immediate player position with no delay.
	var player_position = PlayerInfo.get_true_player_position()
	var look_at = PlayerInfo.get_player_look_direction()
	
	var url = "/location/impression/%f/%f/%f/%f/%f/%f/%d"\
		% [player_position[0], player_position[2], player_position[1], look_at.x, look_at.z, look_at.y, Session.session_id]
	
	# Medium to low priority - we do want it to arrive sometime soon, but doesn't have to be immediate
	ThreadPool.enqueue_task(ThreadPool.Task.new(self, "make_position_request", url), 15)


# Send the position data (via premade url) to the server - to be run in a thread
func make_position_request(url):
	ServerConnection.get_http(url)
	logger.info("sent position to server at url %s" % [url])