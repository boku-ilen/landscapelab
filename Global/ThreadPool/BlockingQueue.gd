extends Node

var _sem = Semaphore.new()
var _mutex = Mutex.new()

var _queue = []


# Place an element at the back of the queue.
# This function is blocking if the queue is currently locked (being accessed).
func enqueue(val, priority):
	while _mutex.try_lock() == ERR_BUSY:
		continue
	
	_queue.push_front([val, priority])
	# TODO: Naive implementation of a priority queue. This is too inefficient!
	_queue.sort_custom(self, "sort_priority")
	_mutex.unlock()
	_sem.post()


# Removes and returns the element at the front of the queue.
# This function is blocking if the queue is currently locked (being accessed) or empty.
# It may return null if there was an error with decrementing the Semaphore.
func dequeue():
	if _sem.wait() == ERR_BUSY:
		return null
	
	while _mutex.try_lock() == ERR_BUSY:
		continue
	var val = _queue.pop_back()[0]
	_mutex.unlock()
	return val
	

# Custom sort function for the priority queue - the priority is the second element in
#  the array (the first is the actual Task)
func sort_priority(v1, v2):
	return v1[1] < v2[1]
