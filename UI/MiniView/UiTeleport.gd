extends TextureButton

# Load the point of interests listview
var poi_list_view = load("res://UI/PointsOfInterest/PoI.tscn").instance()
var list_container


func _ready():
	list_container = get_child(0)


# Emit a global signal for using the pc-perspective onclick teleport.
func _pressed():
	GlobalSignal.emit_signal("teleport")
	GlobalSignal.connect("poi_clicked", self, "_extract_poi_metadata")
	# If accidently clicked twice, the points of interest do not get loaded twice
	_clear_list_container()
	_load_pois()


# Loads all Points of Interests from the server
func _load_pois():
	var pois = ServerConnection.get_json("/location/scenario/list.json")["10"]["locations"] #Session.get_current_scenario()["locations"]
	
	var poi_list = poi_list_view.get_child(1)
	
	var index = 0
	# create a Point of Interest for each entry in the locations
	for poi in pois:
		var text = pois[poi]["name"]
		poi_list.add_item(text)
		# Create a vector for the locations data (only contains "x" and "z"-axis) 
		var location_coordinates = Vector3(pois[poi]["location"][0], 0, pois[poi]["location"][1])
		# The ID in the list is not necessarily the same as the id in the json-file thus we have to
		# set the poi-id in the metadata
		poi_list.set_item_metadata(index, location_coordinates)
		
		index += 1
	
	list_container.add_child(poi_list_view)
	
	
func _clear_list_container():
	for list in list_container.get_children():
		list_container.remove_child(list)


func _extract_poi_metadata(index):
	var item_coordinates = poi_list_view.get_child(1).get_item_metadata(index)
	GlobalSignal.emit("poi_port", item_coordinates)