extends Node

# this is the new communication implementation based checked the godot websocket
# we assume the landscapelab (former client) to be the master of potential
# several connections to endpoints like the qgis-plugin or to LabTable(s)

var _ws_server: WebSocketServer
var _write_mode = WebSocketPeer.WRITE_MODE_TEXT
var _clients = {}
var _handlers = {}
var _message_stack = {}

const LOG_MODULE := "WEBSOCKET"

# initialize the websocket server and listening for client connections
func _ready():
	self._ws_server = WebSocketServer.new()
	# FIXME: Seems like this is not needed anymore?
	# self._ws_server.bind_ip = Settings.get_setting("server", "bind_ip")
	var port = Settings.get_setting("server", "port")

	# Connect base signals for server client communication
	self._ws_server.connect("client_connected",Callable(self,"_connected"))
	self._ws_server.connect("client_disconnected",Callable(self,"_disconnected"))
	self._ws_server.connect("message_received",Callable(self,"_on_data"))

	# try to start listening
	var err = _ws_server.listen(port)
	if err:
		logger.error("server bindings could not be initialized (port: %s)" % [port], LOG_MODULE)
		# FIXME: server binding could not be initialized
	else:
		logger.info("websocket server initialized checked port %s" % [port], LOG_MODULE)


# close the server checked unload
func _exit_tree():

	# free the client connection list
	_clients.clear()
	# FIXME: actively disconnect clients?

	# send the event handler that the server stops
	for handler in _handlers:
		handler.on_server_remove()
	_handlers.clear()

	# stop listening
	self._ws_server.stop()


# add a request handler which implements the request procession
func register_handler(handler: AbstractRequestHandler):
	if handler.protocol_keyword:
		if not self._handlers.has(handler.protocol_keyword):
			self._handlers[handler.protocol_keyword] = handler
			return true
	return false


# remove_at the request handler upon request
func unregister_handler(handler: AbstractRequestHandler):
	if handler.protocol_keyword:
		if self._handlers.erase(handler.protocol_keyword):
			return true
	return false


# we have to frequently and actively check for new messages
# TODO: do we need to do this multithreaded?
func _process(_delta):
	self._ws_server.poll()


# handle a new client connection and register it
func _connected(id, proto):
	logger.info("Connected client %s with protocol %s" % [id, proto], LOG_MODULE)
	self._clients[id] = self._ws_server.get_peer(id)
	self._clients[id].set_write_mode(self._write_mode)


# remove_at a client connection
func _disconnected(id, was_clean=false):
	logger.info("Disconnected client %s (clean: %s)" % [id, was_clean], LOG_MODULE)
	if self._clients.has(id):
		self._clients.erase(id)


func _on_data(id, message):
	
	# unpack the received data
	var packet = self._ws_server.get_peer(id).get_packet()
	var string = packet.get_string_from_utf8()
	var test_json_conv = JSON.new()
	test_json_conv.parse(string)
	var json_result = test_json_conv.get_data()
	
	# Validation
	if not json_result.error == OK:
		logger.error("Received invalid JSON data in request: %s" % [string], LOG_MODULE)
		return
	
	var json_dict = json_result.result
	
	logger.debug("received request from %s with data %s" % [id, json_dict], LOG_MODULE)
	
	if not json_dict.has("message_id"):
		logger.error("Missing message ID in request! Aborting...", LOG_MODULE)
		return
	
	var message_id = json_dict["message_id"]
	
	if not json_dict.has("keyword"):
		logger.error("Missing keyword field in request with ID %s!" % [message_id], LOG_MODULE)
		return
	
	var keyword = json_dict["keyword"]
	
	# Remove these meta parameters for further handling
	json_dict.erase("message_id")
	json_dict.erase("keyword")
	
	# detect if this is an answer to a sent message
	if _message_stack.has(message_id):
		var handler = _message_stack.get(_message_stack)
		handler.on_answer(json_dict )  # FIXME: how to find according client_id?
		
	# not an answer so get the correct target and forward the message
	else:
		if _handlers.has(keyword):
			var handler = _handlers.get(keyword)
			var answer = handler.handle_request(json_dict)
			if answer:
				# TOOD: set "success" to false if something was invalid
				answer["success"] = true
				_send_data(answer, null, message_id)  # FIXME: how to find according client_id?
			
		else:
			logger.warn("received a message without registered keyword %s" % [keyword], LOG_MODULE)


func broadcast(data):
	_send_data(data)


# FIXME: we could implement a send function like this but we have to determine which client id
# FIXME: is the receiving part - or broadcast it and the client decides what to do with the event
func _send_data(data: Dictionary, client_id=-1, message_id=null):
	# if id is null broadcast to all connected clients
	if client_id == -1:
		logger.debug("starting broadcast", LOG_MODULE)
		for current_client_id in _clients:
			_send_data(data, current_client_id, message_id)
		logger.debug("ending broadcast", LOG_MODULE)

	else:
		if message_id:
			data["message_id"] = message_id
		else:
			data["message_id"] = Time.get_ticks_msec() 
		logger.debug("send msg: %s to client %s" % [data, client_id], LOG_MODULE)
		var message = JSON.stringify(data)
		self._ws_server.get_peer(client_id).put_packet(message.to_utf8_buffer())
