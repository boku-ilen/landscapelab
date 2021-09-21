extends Viewport


#
# FIXME: Rewrite filming functionality (maybe use a cpp library as gdnative
# plugin for filming actual videos)
#


var timer: Timer
export(float) var fps: float = 4.0
export(float) var asset_type_to_color: int = 2


func _ready():
	pass
#	timer = Timer.new()
#	timer.set_one_shot(false)
#	timer.set_timer_process_mode(0)
#	timer.set_wait_time(1.0 / fps)
#	timer.set_autostart(false)
#	timer.connect("timeout", self, "make_training_screenshot_pair")
#	UISignal.connect("toggle_imaging_recording", self, "_on_record")
#
#	self.add_child(timer)


func _on_record():
	if timer.is_stopped():
		timer.start(0.0)
	else:
		timer.stop()


func _get_screenshot_from_viewport():
	# Retrieve the captured image
	var img = get_texture().get_data()
  
	# Flip it on the y-axis (because it's flipped)
	img.flip_y()
	
	return img


func make_screenshot():
	var img = _get_screenshot_from_viewport()
	
	# Save to a file, use the current time for naming
	var screenshot_filename = _get_screenshot_filename()
	
	# Medium to low priority - we do want it to save sometime soon, but doesn't have to be immediate
	ThreadPool.enqueue_task(ThreadPool.Task.new(self, "save_screenshot", [img, screenshot_filename]), 15)


# Captures two screenshots: One normal, one with a selected asset highlighted in pink.
# Used for machine learning training data.
func make_training_screenshot_pair():
	var normal_img = _get_screenshot_from_viewport()
	
	# Emit signal to color all assets of asset_type_to_color pink
	GlobalSignal.emit_signal("toggle_asset_debug_color", asset_type_to_color, true)
	
	# Wait for a frame so that the new material is definitely applied
	VisualServer.force_draw()
	
	var colored_img = _get_screenshot_from_viewport()
	
	# Remove color overwrite from above
	GlobalSignal.emit_signal("toggle_asset_debug_color", asset_type_to_color, false)
	
	# Get the time here and pass it as an argument to prevent tiny differences, causing
	#  different screenshot filenames
	var time = OS.get_system_time_msecs()
	
	# Save to a file, use the current time for naming
	var normal_screenshot_filename = _get_screenshot_filename_with_additional_flag(1, time)
	var colored_screenshot_filename = _get_screenshot_filename_with_additional_flag(2, time)
	
	# Medium to low priority - we do want it to save sometime soon, but doesn't have to be immediate
	ThreadPool.enqueue_task(ThreadPool.Task.new(self, "save_screenshot", [normal_img, normal_screenshot_filename]), 15)
	ThreadPool.enqueue_task(ThreadPool.Task.new(self, "save_screenshot", [colored_img, colored_screenshot_filename]), 15)


# Actually save a screenshot - to be run in a thread
func save_screenshot(img_filename_array):
	img_filename_array[0].save_png(img_filename_array[1])
	logger.info("captured screenshot in %s " % [img_filename_array[1]])


func _get_screenshot_filename():
	pass#return "user://videoframe-%d-%d.png" % [Session.session_id, OS.get_system_time_msecs()]


func _get_screenshot_filename_with_additional_flag(flag: int, time: int):
	pass#return "user://%d-videoframe-%d-%d.png" % [flag, Session.session_id, time]
