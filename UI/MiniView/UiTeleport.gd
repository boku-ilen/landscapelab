extends TextureButton

# Load the point of interests listview
onready var poi_list_view = preload("res://UI/PointsOfInterest/PoI.tscn").instance()
onready var list_container = get_node("PointsOfInterestList")


func _ready():
	GlobalSignal.connect("poi_clicked", self, "_extract_poi_metadata")
	# Either one of those options will be clicked => teleport is done
	GlobalSignal.connect("poi_clicked", self, "_hide_list_view")
	GlobalSignal.connect("teleported", self, "_hide_list_view")
	
	# Should only be displayed when teleport is clicked
	poi_list_view.visible = false
	_load_pois()


# Emit a global signal for using the pc-perspective onclick teleport.
func _pressed():
	GlobalSignal.emit_signal("teleport")
	
	poi_list_view.visible = true


# Loads all Points of Interests from the server
func _load_pois():
	var pois = Session.get_current_scenario()["locations"]
	var poi_list = poi_list_view.get_node("VBoxContainer/ItemList")
	
	var index = 0
	# create a Point of Interest for each entry in the locations
	for poi in pois:
		var text = pois[poi]["name"]
		poi_list.add_item(text)
		# Create a vector for the locations data (only contains "x" and "z"-axis)
		# As the coordinates from the server are responded in a different type we have to use a "-" on the x-axis
		var fixed_pos = [-pois[poi]["location"][0], pois[poi]["location"][1]]
		
		# The ID in the list is not necessarily the same as the id in the json-file thus we have to
		# set the poi-id in the metadata
		poi_list.set_item_metadata(index, fixed_pos)
		
		index += 1
	
	list_container.add_child(poi_list_view)


# We saved the location coordinates in the metadata of the list items, if one is clicked emit a signal with this 
# data that can be handled in another script
func _extract_poi_metadata(index):
	var fixed_pos = poi_list_view.get_node("VBoxContainer/ItemList").get_item_metadata(index)
	GlobalSignal.emit_signal("poi_teleport",  Offset.to_engine_coordinates(fixed_pos))


func _hide_list_view(index=null):
	poi_list_view.visible = false