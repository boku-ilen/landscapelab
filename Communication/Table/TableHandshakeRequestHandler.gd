extends AbstractRequestHandler
class_name RemoveTokenRequestHandler

#
# Example request data:
# {
#    "keyword": "TABLE_HANDSHAKE",
#    "detected_brick_shape_color_pairs": ["SQUARE", "RED"], ["RECTANGLE", "RED"]]
# }
#


# set the protocol keyword
func _init():
	protocol_keyword = "TABLE_HANDSHAKE"


func handle_request(request: Dictionary) -> Dictionary:
	var result = {}
	
	# TODO: Send gamestate info (use separate function because that might be relevant in multiple places?)
	#    "keyword": "GAMESTATE_INFO",
	#    "used_bricks": [],  # [[shape, color, icon_svg, disappear_after_seconds], ...]
	#    "scores": [],  # [[id, max_value], ...]
	#    "start_position": [0.0, 0.0],
	#    "start_extent": [0.0, 0.0],  # FIXME: or zoom level?
	#    "projection": ""  # EPSG Code (optional, default is Austria Lambert)
	
	return result
