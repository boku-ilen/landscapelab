extends Node

var _sem = Semaphore.new()
var _mutex = Mutex.new()

var _queue = []

func enqueue(val):
	while _mutex.try_lock() == ERR_BUSY:
		continue
	
	_queue.push_back(val)
	_mutex.unlock()
	_sem.post()

func dequeue():
	if _sem.wait() == ERR_BUSY:
		return null
	
	while _mutex.try_lock() == ERR_BUSY:
		continue
	var val = _queue.pop_front()
	_mutex.unlock()
	return val