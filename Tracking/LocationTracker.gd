extends Spatial

export var interval = 1

var timer

func _ready():
	go()

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
	ThreadPool.enqueue_task(ThreadPool.Task.new(self, "send_position", []))

func send_position(userdata):
	var player_position = PlayerInfo.get_true_player_position()
	var look_at = PlayerInfo.get_player_look_direction()

	var url = "/location/impression/%f/%f/%f/%f/%f/%f/%d"\
		% [player_position[0], player_position[2] ,player_position[1], look_at.x, look_at.z, look_at.y, Session.id]
	
	ServerConnection.get_http(url)
