extends Node3D
class_name RoofBase

var addon_layer: GeoFeatureLayer
var addon_object: PackedScene
var addons: Array
var building_metadata: Dictionary


# Use after instantiate as constructor
func with_data(_addon_layer, _addon_object, _addons, _building_metadata):
	addon_layer = _addon_layer
	addon_object = _addon_object
	addons = _addons
	building_metadata = _building_metadata
	return self
