extends Node3D
class_name RoofBase

var fid
var addon_layers: Dictionary # String to GeoLayer
var addon_objects: Dictionary # String to Object
var building_metadata: Dictionary


# Use after instantiate as constructor
func with_data(
	_fid,
	_addon_layers: Dictionary, 
	_addon_objects: Dictionary,
	_building_metadata: Dictionary):
	
	fid = _fid
	addon_layers = _addon_layers
	addon_objects = _addon_objects
	building_metadata = _building_metadata
	return self
