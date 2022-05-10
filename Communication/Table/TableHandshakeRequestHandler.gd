extends AbstractRequestHandler
class_name TableHandshakeRequestHandler

#
# 
#

var table_communicator: TableCommunicator  # To be injected


# set the protocol keyword
func _init():
	protocol_keyword = "TABLE_HANDSHAKE"


func handle_request(request: Dictionary) -> Dictionary:
	var result = table_communicator.get_gamestate_info(request)
	
	return result
