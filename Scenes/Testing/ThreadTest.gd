extends Spatial

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

var time = 0

func _process(delta):
	time += delta
	
	if time > 1:
		ThreadPool.enqueue_task(ThreadPool.Task.new(self, "add_and_print", [1, 2]))

func add_and_print(data):
	var t = Timer.new()
	t.set_wait_time(rand_range(0.5, 1.5))
	t.set_one_shot(true)
	self.add_child(t)
	t.start()
	yield(t, "timeout")
	t.queue_free()
	
	print(data[0] + data[1])