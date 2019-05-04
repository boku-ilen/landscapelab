extends Spatial

export var interval = 1  # in seconds  FIXME: make this configurable

var timer


# initialize the internal timer but don't start it yet
func _ready():
	timer = Timer.new()
	timer.set_one_shot(false)
	timer.set_timer_process_mode(0)
	timer.set_wait_time(interval)
	timer.set_autostart(false)
	timer.connect("timeout", self, "start_send_position")
	self.add_child(timer)


# we are starting the tracking - it is called by the play button
func start_tracking():
	timer.start()


func toggle_pause_tracking():
	if timer.paused:
		timer.start()
	else:
		timer.stop()


# this function stops the tracking - it is called by the stop button
func stop_tracking():
	timer.stop()


# we start a thread which takes a screenshot and a thread which sends 
# the location information to the server
func start_send_position():
	ThreadPool.enqueue_task(ThreadPool.Task.new(self, "send_position", []))
	ThreadPool.enqueue_task(ThreadPool.Task.new(self, "save_screenshot", []))


# https://godotengine.org/qa/12164/as-in-the-game-to-take-a-screenshot
func save_screenshot(userdata):
	
	# start screen capture
	get_viewport().queue_screen_capture()
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")

	# get screen capture
	var capture = get_viewport().get_screen_capture()
	# save to a file
	var timestamp = OS.get_datetime()
	capture.save_png("user://screenshot-%d%d%d-%d%d%d-%d.png" % [timestamp["year"], timestamp["month"], timestamp["day"], timestamp["hour"], timestamp["minute"], timestamp["secound"], Session.id])


func send_position(userdata):
	var player_position = PlayerInfo.get_true_player_position()
	var look_at = PlayerInfo.get_player_look_direction()

	var url = "/location/impression/%f/%f/%f/%f/%f/%f/%d"\
		% [player_position[0], player_position[2] ,player_position[1], look_at.x, look_at.z, look_at.y, Session.id]
	
	ServerConnection.get_http(url)
