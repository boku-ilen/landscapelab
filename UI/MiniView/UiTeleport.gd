extends TextureButton

# Load the point of interests listview
var poi_list_view = load("res://UI/PointsOfInterest/PoI.tscn").instance()
var list_container


# Emit a global signal for using the pc-perspective onclick teleport.
func _pressed():
	GlobalSignal.emit_signal("teleport")


# Loads all Points of Interests from the server
func _load_pois():
	var pois = ServerConnection.get_json("/")
	
	var poi_list = poi_list_view.get_child(1)
	
	var index = 0
	# create an ItemList entry for every specific asset of the type
	for poi in pois:
		var text = pois["TODO"]
		poi_list.add_item(text)
		# The ID in the list is not necessarily the same as the id in the json-file thus we have to
		# set the asset id in the metadata
		poi_list.set_item_metadata(index, poi)
		
		index += 1
	
	list_container.add_child(poi_list_view)