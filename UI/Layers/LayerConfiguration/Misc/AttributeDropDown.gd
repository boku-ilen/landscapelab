extends OptionButton


var feature_layer: FeatureLayer setget set_feature_layer


func set_feature_layer(layer: FeatureLayer):
	feature_layer = layer
	var exemplary_feature = feature_layer.geo_feature_layer.create_feature()
	var attrib_dict: Dictionary = exemplary_feature.get_attributes()
	# FIXME: also remove the feature afterwards (shouldnt this work?)
	#feature_layer.geo_feature_layer.remove_feature(exemplary_feature)
	
	for attrib in attrib_dict.keys():
		add_item(attrib)


func set_selected_by_text(tex: String):
	var idx = 0
	var t = items
	for item in items:
		if not item is String: continue
		if item == tex:
			select(idx)
			return
		
		idx +=1
