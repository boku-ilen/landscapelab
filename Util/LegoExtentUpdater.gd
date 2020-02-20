extends Spatial


#
# Regularly fetches the newest Lego extent from the server and draws it.
#


export(int) var lego_board_assettype_id = 6
export(int) var top_left_id = 14
export(int) var bottom_right_id = 15

onready var drawer = get_node("LegoExtentDrawer")
onready var requester = get_node("RegularServerRequest")


# Called when the node enters the scene tree for the first time.
func _ready():
	# TODO: There's currently no display radius for this asset type, so we can use the position 0.0, 0.0
	#  But maybe it would make sense to have a display radius?
	requester.set_request("/assetpos/get_near/by_assettype/%d/0.0/0.0.json" % [lego_board_assettype_id])
	requester.connect("new_response", self, "_on_new_response", [], CONNECT_DEFERRED)


func _on_new_response(response):
	if not response or not response.has("assets"):
		logger.warning("Invalid response for Lego extent request!")
		return
	
	var top_left_vector
	var bottom_right_vector
	
	# Get the vectors from the assetpositions with the corresponding asset id
	var done = 0  # We need this because a null check fails against a (0, 0) vector which might be correct
	
	for assetpos_id in response["assets"]:
		var assetpos = response["assets"][assetpos_id]
		
		if assetpos["asset_id"] == top_left_id:
			var pos = [-assetpos["position"][0], assetpos["position"][1]]
			top_left_vector = Offset.to_engine_coordinates(pos)
			done += 1
		elif assetpos["asset_id"] == bottom_right_id:
			var pos = [-assetpos["position"][0], assetpos["position"][1]]
			bottom_right_vector = Offset.to_engine_coordinates(pos)
			done += 1
	
	# Convert the vectors to 3D vectors
	if done == 2:
		var top_left_vector_3d = Vector3(top_left_vector.x, 0, top_left_vector.y)
		var bottom_right_vector_3d = Vector3(bottom_right_vector.x, 0, bottom_right_vector.y)
		
		drawer.set_mesh_extent(top_left_vector_3d, bottom_right_vector_3d)
		drawer.visible = true
	else:
		logger.debug("Lego extent not updated but hidden due to missing data about the extent")
		drawer.visible = false
