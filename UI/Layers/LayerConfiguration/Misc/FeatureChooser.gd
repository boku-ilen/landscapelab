extends VBoxContainer

#
# Simplifies choosing an explicit feature of a feature-layer
#

@export var geodata_chooser: GeodataChooser


func _ready():
	geodata_chooser.new_layer_selected.connect(func(new_layer):
		set_visible(true)
		load_from_layer(new_layer))


func load_from_layer(geolayer: GeoFeatureLayer):
	# Remove all previously loaded features
	$OptionButton.clear()
	
	# Create an option entry
	var idx := 0
	for feature in geolayer.get_all_features():
		var casted_feature: GeoFeature = feature
		
		# See if the feature has a displayable name otherwise show id
		var display_text = casted_feature.get_attribute("name")
		if display_text == "" or display_text == null:
			display_text = var_to_str(casted_feature.get_id())
		$OptionButton.add_item(display_text)
		
		# Store feature as meta data entry
		$OptionButton.set_item_metadata(idx, feature)
		
		idx += 1


func get_currently_selected_feature():
	return $OptionButton.get_item_metadata($OptionButton.selected)
