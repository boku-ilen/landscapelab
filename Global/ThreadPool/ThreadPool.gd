extends Node

#
# Since starting a thread is expensive (it causes noticeable stutters), this
# singleton provides pre-started threads which you can delegate work to.
# Starting a function in one of these pooled threads is non-blocking.
#
# Note that nodes which have active enqueued tasks in the ThreadPool may not be
# freed until all these functions are done - otherwise, they may be freed while
# the method is still being executed in a thread, causing a crash!
#

const BlockingQueue = preload("res://Global/ThreadPool/BlockingQueue.gd")

const THREAD_COUNT_AT_PRIORITY = [
	4,
	4
]

var task_queues = []
var threads = []


func _ready():
	# For each priority, instance as many threads as that priority calls for, and one blocking queue
	for priority in range(0, THREAD_COUNT_AT_PRIORITY.size()):
		task_queues.append(BlockingQueue.new())
		threads.append([])
		
		for thread_num in range(0, THREAD_COUNT_AT_PRIORITY[priority]):
			threads[priority].append(Thread.new())
			threads[priority][thread_num].start(self, "thread_worker", task_queues[priority])


# This is the function which the thread workers are constantly running
func thread_worker(task_queue):
	while true:
		# If there are tasks in the queue: Fetch one and execute it
		var task = task_queue.dequeue()
		
		if task is Task:
			task.execute()


# Puts a task (obj + method) into the task queue.
# Optionally, a priority can be given. It should be scaled between 0 (very low) and 99 (very high).
func enqueue_task(task, priority=0):
	# Clamp priority between 0 and 99 to be safe
	priority = clamp(priority, 0, 99)
	
	# Get the task_queues index which corresponds to the priority (scale the priority to the number of threads)
	var index = THREAD_COUNT_AT_PRIORITY.size() - 1 - int((priority / 100.0) * THREAD_COUNT_AT_PRIORITY.size())
	
	task_queues[index].enqueue(task)


# This class groups an object, a method and parameters for the method. It provides 
# an 'execute' function which calls the provided method on the provided object, 
# with the set parameters. Note that the function has to take the arguments in the 
# form of a single array.
class Task:
	var obj
	var ref
	var method
	var params
	
	signal finished


	func _init(obj, method, params=null):
		self.obj = obj
		self.ref = weakref(obj)
		self.method = method
		self.params = params


	func execute():
		# A simple null check is not enough here, as the node might still hold something, but be freed already.
		# Thus, we check the validity of the node by testing whether a weak reference to the object is still valid.
		# As proposed here: https://godotengine.org/qa/10085/how-to-know-a-node-is-freed-or-deleted
		# Note that this should always succeed if all usages of the ThreadPool are correctly programmed!
		if ref.get_ref():
			if params:
				obj.call(method, params) 
			else:
				obj.call(method)
		else:
			pass
			# FIXME: Would be nice to log this, but this is likely not thread-safe either!
			#logger.error("Thread was supposed to call %s, but the object didn't exist anymore!" % [method])
		
		# FIXME: Should be call_deferred("emit_signal", "finished"), but we've encountered a problem
		# where that is not executed if there are two very similar taks (execute the same function on
		# objects of the same type).
		# Thus, take care to use CONNECT_DEFERRED when connecting to this signal!
		emit_signal("finished")
