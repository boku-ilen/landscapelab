extends Object

var _sem = Semaphore.new()
var _mutex = Mutex.new()

var _queue = []


# Place an element at the back of the queue.
# This function is blocking if the queue is currently locked (being accessed).
func enqueue(val):
	while not _mutex.try_lock():
		continue
	
	_queue.push_front(val)
	_mutex.unlock()
	_sem.post()


# Removes and returns the element at the front of the queue.
# This function is blocking if the queue is currently locked (being accessed) or empty.
# It may return null if there was an error with decrementing the Semaphore.
func dequeue():
	if not _sem.try_wait():
		return null
	
	while not _mutex.try_lock():
		continue
	var val = _queue.pop_back()
	_mutex.unlock()
	return val


# Returns the number of elements currently in the queue
func get_size():
	return _queue.size()
