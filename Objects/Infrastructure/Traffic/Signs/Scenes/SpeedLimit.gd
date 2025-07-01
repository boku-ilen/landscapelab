extends Node3D

var feature: GeoFeature : 
	set(new_geo_feature):
		feature = new_geo_feature
		$Begin.text = feature.get_attribute("context")
