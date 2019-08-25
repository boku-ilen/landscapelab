extends TextureButton

# Load the point of interests listview
var poi_list_view
var list_container


func _ready():
	list_container = get_child(0)
	GlobalSignal.connect("poi_clicked", self, "_extract_poi_metadata")
	GlobalSignal.connect("teleported", self, "_clear_list_container")


# Emit a global signal for using the pc-perspective onclick teleport.
func _pressed():
	GlobalSignal.emit_signal("teleport")
	# If accidently clicked twice, the points of interest do not get loaded twice
	_clear_list_container()
	_load_pois()


# Loads all Points of Interests from the server
func _load_pois():
	var pois = Session.get_current_scenario()["locations"]
	
	poi_list_view = load("res://UI/PointsOfInterest/PoI.tscn").instance()
	var poi_list = poi_list_view.get_child(1)
	
	var index = 0
	# create a Point of Interest for each entry in the locations
	for poi in pois:
		var text = pois[poi]["name"]
		poi_list.add_item(text)
		# Create a vector for the locations data (only contains "x" and "z"-axis)
		# As the coordinates from the server are responded in a different type we have to use a "-" on the x-axis
		var fixed_pos = [-pois[poi]["location"][0], pois[poi]["location"][1]]
		# With Offset.to_engine_coordinates change webmercator to the according in-game coordinates
		var location_coordinates = Offset.to_engine_coordinates(fixed_pos)
		var test = WorldPosition.get_position_on_ground(Vector3(location_coordinates.x, 0, location_coordinates.y))
		# The ID in the list is not necessarily the same as the id in the json-file thus we have to
		# set the poi-id in the metadata
		poi_list.set_item_metadata(index, location_coordinates)
		
		index += 1
	
	list_container.add_child(poi_list_view)


func _clear_list_container():
	for list in list_container.get_children():
		list_container.remove_child(list)
		poi_list_view = null


# We saved the location coordinates in the metadata of the list items, if one is clicked emit a signal with this 
# data that can be handled in another script
func _extract_poi_metadata(index):
	var location_coordinates = poi_list_view.get_child(1).get_item_metadata(index)
	GlobalSignal.emit_signal("poi_teleport", location_coordinates)