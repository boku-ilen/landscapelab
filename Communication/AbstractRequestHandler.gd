extends Node
class_name AbstractRequestHandler

# this is the base class for all request handlers. Each request handler implements
# answering a certain request (protocol_keyword). This has to be set by the specific
# subclass

var protocol_keyword = null  # each subclass has to set this to identify which requests are handled
var parameter_list = {}  # FIXME: do we need this?
var _server = CommunicationServer  # internal reference to the singleton


func _init():
	assert(self.protocol_keyword, "AbstractRequestHandler is an abstract class - it must not be initialized")
	if not self._server.register_handler(self):
		logger.error("Could not register keyword {}".format(self.protocol_keyword))

func _exit_tree():
	self._server.unregister_handler(self)


func handle_request(request: Dictionary) -> Dictionary:
	assert(protocol_keyword, "AbstractRequestHandler.handle_request has to be implemented")
	return {}

# FIXME: do we want to provide a send_request?


# this is an event handler sent to the request handlers before the server removes this request handler
func on_server_remove():
	self._server = null
