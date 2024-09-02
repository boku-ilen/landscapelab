extends Node3D
class_name RoofBase

var addon_layers: Dictionary # String to GeoLayer
var addon_objects: Dictionary # String to Object
var addons: Dictionary
var building_metadata: Dictionary


# Use after instantiate as constructor
func with_data(
	_addon_layers: Dictionary, 
	_addon_objects: Dictionary, 
	_addons: Dictionary, 
	_building_metadata: Dictionary):
	
	addon_layers = _addon_layers
	addon_objects = _addon_objects
	addons = _addons
	building_metadata = _building_metadata
	return self
