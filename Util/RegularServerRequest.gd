extends Node

#
# Sends a server request at regular intervals.
# Emits the 'new_response' signal when a new response is available.
# The latest response is also accessible via get_latest_response().
# 
# If the request must send the latest data of something, a custom function
# can be given via set_custom_request_getter(), which is called directly
# before doing the new server request.
#


export(String) var request
export(float) var interval = 1 setget set_interval, get_interval

onready var timer = get_node("Timer") as Timer

signal new_response(response)

var _latest_response
var _request_getter


func _ready():
	# If the interval has been set previously, apply it to the timer node now
	timer.wait_time = interval
	
	timer.connect("timeout", self, "_on_timer_timeout")
	start()


# Restart the regular requests
func start():
	timer.start()


# Pause the regular requests
func pause():
	timer.stop()


# Returns the latest response
func get_latest_response():
	return _latest_response


# Change the request which will be sent to the server next time the interval is reached
func set_request(new_request):
	request = new_request


# A lambda-ish way of setting a custom function which is called right before doing
#  the next server request. The function should return a string with a server request.
func set_custom_request_getter(object, function_name):
	_request_getter = RequestGetter.new(object, function_name)


func _on_timer_timeout():
	logger.debug("Regular requester %s enqueueing new regular server request" % [name])
	
	# We give this task a medium to high priority, since the regular results should arrive
	#  approximately with the given interval.
	ThreadPool.enqueue_task(ThreadPool.Task.new(self, "_do_server_request", []), 70.0)


func _do_server_request(args):
	# If we have a custom request getter function, use it to get the latest request
	if _request_getter:
		request = _request_getter.object.call(_request_getter.function)
	
	# Never cache here since when we do it regularly, we probably expect changes
	var response = ServerConnection.get_json(request, false)
	
	# TODO: Make sure this is thread-safe together with get_latest_response()!
	#  We need a mutex otherwise
	_latest_response = response
	
	emit_signal("new_response", _latest_response)


func set_interval(new_interval):
	interval = new_interval
	
	# If the node isn't actually in the game yet, we don't have the timer node yet,
	#  in that case it will be applied in _ready()
	if is_inside_tree():
		timer.wait_time = interval


func get_interval():
	return interval


class RequestGetter:
	var object
	var function
	
	func _init(_object, _function):
		self.object = _object
		self.function = _function
