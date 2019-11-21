extends Viewport


var timer: Timer
var fps: float = 10


func _ready():
	timer = Timer.new()
	timer.set_one_shot(false)
	timer.set_timer_process_mode(0)
	timer.set_wait_time(1.0 / fps)
	timer.set_autostart(false)
	timer.connect("timeout", self, "make_screenshot")
	
	self.add_child(timer)


func _input(event: InputEvent) -> void:
	if event.is_action_released("toggle_imaging_recording"):
		if timer.is_stopped():
			timer.start(0.0)
		else:
			timer.stop()


func make_screenshot():
	# Retrieve the captured image
	var img = get_texture().get_data()
  
	# Flip it on the y-axis (because it's flipped)
	img.flip_y()
	
	# Save to a file, use the current time for naming
	var timestamp = OS.get_datetime()
	var screenshot_filename = "user://videoframe-%d%d%d-%d%d%d-%d-%d.png" % [timestamp["year"], timestamp["month"],
	 timestamp["day"], timestamp["hour"], timestamp["minute"], timestamp["second"], randi(), Session.session_id]
	
	img.save_png(screenshot_filename)
