extends AbstractRequestHandler
class_name NewExtentRequestHandler

#
# Example request data:
# {
#    "keyword": "TABLE_EXTENT",
#    "min_x": 100.0,
#    "min_y": 100.0,
#    "max_x": 200.0,
#    "max_y": 150.0
# }
#

var table_communicator: TableCommunicator  # To be injected


# set the protocol keyword
func _init():
	protocol_keyword = "TABLE_EXTENT"


func handle_request(request: Dictionary) -> Dictionary:
	var result = {}
	
	return result
