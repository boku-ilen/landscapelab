extends Node

# this is the new communication implementation based on the godot websocket
# we assume the landscapelab (former client) to be the master of potential
# several connections to endpoints like the qgis-plugin or to LabTable(s)

var _ws_server: WebSocketServer
var _write_mode = WebSocketPeer.WRITE_MODE_TEXT  # TODO: or do we need BINARY?
var _clients = {}
var _handlers = {}


# initialize the websocket server and listening for client connections
func _ready():
	self._ws_server = WebSocketServer.new()
	var port = 1234 # FIXME: read from settings
	var supported_protocols = [] # FIXME: read from settings

	# Connect base signals for server client communication
	self._ws_server.connect("client_connected", self, "_connected")
	self._ws_server.connect("client_disconnected", self, "_disconnected")
	self._ws_server.connect("client_close_request", self, "_close_request")
	self._ws_server.connect("data_received", self, "_on_data")

	# try to start listening
	var err = _ws_server.listen(port, supported_protocols, false)
	if err:
		# FIXME: server binding could not be initialized
		pass


# close the server on unload
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


# remove the request handler upon request
func unregister_handler(handler: AbstractRequestHandler):
	if handler.protocol_keyword:
		if self._handlers.erase(handler.protocol_keyword):
			return true
	return false


# we have to frequently and actively check for new messages
# TODO: do we need to do this multithreaded?
func _process(_delta):
	if self._ws_server.is_listening():
		self._ws_server.poll()


# handle a new client connection and register it
func _connected(id, proto):
	logger.info("Connected client {} with protocol {}".format([id, proto]))
	self._clients[id] = self._ws_server.get_peer(id)
	self._clients[id].set_write_mode(self._write_mode)


# remove a client connection
func _disconnected(id, was_clean=false):
	logger.info("Disconnected client {} (clean: {})".format([id, was_clean]))
	if self._clients.has(id):
		self._clients.erase(id)


func _close_request(id, code, reason):
	logger.info("Disconnection request from client {} (code: {}, reason: {})".format([id, code, reason]))
	# TODO: forward to _disconnect() ?


func _on_data(id):
	var packet = self._ws_server.get_peer(id).get_packet()
	logger.debug("received request from {} with data {}".format([id, packet]))
	# FIXME: implement


# FIXME: we could implement a send function like this but we have to determine which client id
# FIXME: is the receiving part - or broadcast it and the client decides what to do with the event
func _send_data(data, client_id=null):

	# if id is null broadcast to all connected clients
	if not client_id:
		for client in _clients:
			_send_data(data, client.id)

	else:
		logger.debug("send msg: {} to client {}".format(data, client_id))
		# FIXME: to implement
		pass

# FIXME: this is a backward compatibility function which should soon be removed
func get_json(parameter):
	return ""
