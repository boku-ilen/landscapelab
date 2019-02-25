extends Spatial

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

var time = 0

func _process(delta):
	time += delta
	
	if time > 1:
		ThreadPool.enqueue_task(ThreadPool.Task.new(self, "add_and_print", [1, 2]))
		ThreadPool.enqueue_task(ThreadPool.Task.new(self, "add_and_print", [1, 3]))
		ThreadPool.enqueue_task(ThreadPool.Task.new(self, "add_and_print", [1, 4]))

func add_and_print(data):
	print(data[0] + data[1])