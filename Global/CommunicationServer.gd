extends Node


# this is the new communication implementation based on the godot websocket
# we assume the landscapelab (former client) to be the master of potential
# several connections to endpoints like the qgis-plugin or to LabTable(s)
class CommunicationServer:

	var _ws_server: WebSocketServer
	var _clients = {}


	# initialize the websocket server and listening for client connections
	func _ready():
		self._ws_server = WebSocketServer.new()
		var port = "" # FIXME: read from settings
		var supported_protocols = "" # FIXME: read from settings
		var err = _ws_server.listen(port, supported_protocols, false)
		if err:
			# FIXME: server binding could not be initialized
			pass


	# close the server on unload
	func _exit_tree():
		_clients.clear()  # FIXME: disconnect clients?
		_ws_server.stop()


	# FIXME: this is a backward compatibility function which should soon be removed
	func get_json(parameter):
		return ""