extends Node

# Since starting a thread is expensive (it causes noticeable stutters), this singleton provides pre-started threads which you can delegate work to.
# Starting a function in one of these pooled threads is non-blocking.

const BlockingQueue = preload("res://Scripts/BlockingQueue.gd")

const THREAD_COUNT : int = 1
var task_queue = BlockingQueue.new()
var threads = []

func _ready():
	# Start THREAD_COUNT threads
	threads.resize(THREAD_COUNT)

	for th in threads:
		th = Thread.new()
		th.start(self, "thread_worker")

# This is the function which the thread workers are constantly running
func thread_worker(data):
	while true:
		# If there are tasks in the queue: Fetch one and execute it
		var task = dequeue_task()
		
		if task is Task:
			task.execute()

# Puts a task (obj + method) into the task queue
func enqueue_task(task):
	task_queue.enqueue(task)

# Returns the item in the task queue which has been there the longest
func dequeue_task():
	return task_queue.dequeue()

# This class groups an object, a method and parameters for the method.
# It provides an 'execute' function which calls the provided method on the provided object, with the set parameters.
# Note that the function has to take the arguments in the form of a single array.
class Task:
	var obj
	var method
	var params
	
	func _init(obj, method, params):
		self.obj = obj
		self.method = method
		self.params = params
	
	func execute():
		obj.call(method, params)