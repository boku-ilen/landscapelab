extends Spatial

var interval = 10
var timer

var thread
var waiting = false

func go():
	if get_child_count() == 0:
		timer = Timer.new()
		timer.set_one_shot(false)
		timer.set_timer_process_mode(0)
		timer.set_wait_time(interval)
		timer.connect("timeout", self, "start_send_position")
		self.add_child(timer)
		timer.start()

func start_send_position():
	if not waiting:
		if(thread == null):
			thread = Thread.new()
		if thread.is_active(): 
			thread.wait_to_finish()
		waiting = true
		thread.start(self, "send_position", null, 1)

func send_position(userdata):
	var p = get_parent().transform.origin
	var forward = (global_transform.origin - get_parent().global_transform.origin) * 100000
	
	var space_state = get_world().direct_space_state
	var result = space_state.intersect_ray(p, p + forward)
	
	var la = Vector3(0,0,0) #look at
	if not result.empty():
		la = result.position
	
	var url = "/location/impression/%f/%f/%f/%f/%f/%f/%d" % [p.x, p.z ,p.y, la.x, la.z, la.y, Session.id]
	#logger.debug("accessing: "+ url)
	ServerConnection.get_http(url)
	waiting = false

func _exit_tree():
	if not thread == null:
		if thread.is_active():
			logger.info("waiting for location tracker thread to finish")
			thread.wait_to_finish()
			logger.info("location tracker thread finished")
		thread = null