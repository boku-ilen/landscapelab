extends AbstractRequestHandler
class_name TableHandshakeRequestHandler

#
# Responds to a handshape request by returning all information about the current GameMode.
# Its main purpose is to map possible Table tokens (included in the request) to
# GameObjectCollections in the current GameMode.
#


var table_communicator: TableCommunicator  # To be injected


# set the protocol keyword
func _init():
	protocol_keyword = "TABLE_HANDSHAKE"


func handle_request(request: Dictionary) -> Dictionary:
	var result = table_communicator.get_gamestate_info(request)
	
	return result
