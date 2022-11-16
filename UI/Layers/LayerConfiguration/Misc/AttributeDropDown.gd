extends OptionButton


var feature_layer: GeoFeatureLayer :
	get:
		return feature_layer
	set(layer):
		feature_layer = layer
		var exemplary_feature = feature_layer.create_feature()
		var attrib_dict: Dictionary = exemplary_feature.get_attributes()
		# FIXME: also remove_at the feature afterwards (shouldnt this work?)
		#feature_layer.geo_feature_layer.remove_feature(exemplary_feature)
		
		for attrib in attrib_dict.keys():
			add_item(attrib)


func set_selected_by_text(tex: String):
	for item_index in range(item_count):
		if get_item_text(item_index) == tex:
			select(item_index)
			return
