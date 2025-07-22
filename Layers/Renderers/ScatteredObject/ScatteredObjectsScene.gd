extends RenderChunk

var height_layer: GeoRasterLayer
var scatter_layer: GeoRasterLayer
var objects: Dictionary
var density: float

var rng := RandomNumberGenerator.new()
var initial_rng_state

var refine_load_distance = 500

var fresh_scenes = {}


func _ready():
	super._ready()


func override_build(center_x, center_y):
	fresh_scenes = {}
	
	for object_raster_id in objects.keys():
		fresh_scenes[object_raster_id] = Node3D.new()
	
	var location_getter = ScatteredLocationsGetter.new(
		center_x,
		center_y,
		size,
		density,
		scatter_layer,
		height_layer,
		objects
	)
	var object_locations = location_getter.get_object_locations()
	
	for object_value in object_locations.keys():
		for location in object_locations[object_value]:
			var new_object = load(objects[object_value]).instantiate()
			new_object.position = location
			fresh_scenes[object_value].add_child(new_object)


func override_apply():
	for child in get_children():
		child.free()
	
	for scene in fresh_scenes.values():
		add_child(scene)
