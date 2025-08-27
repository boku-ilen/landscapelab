extends RenderChunk

var height_layer: GeoRasterLayer
var scatter_layer: GeoRasterLayer
var objects: Dictionary

var rng := RandomNumberGenerator.new()
var initial_rng_state

var refine_load_distance := 200.0

var fresh_scenes = {}


func _ready():
	super._ready()


func override_build(center_x, center_y):
	fresh_scenes = {}
	
	for object_name in objects.keys():
		var object = objects[object_name]
		
		fresh_scenes[object_name] = Node3D.new()
	
		var location_getter = ScatteredLocationsGetter.new(
			center_x,
			center_y,
			size,
			object["density"],
			object.get("randomness", 1.0),
			scatter_layer,
			height_layer,
			object["condition"]
		)
		var object_locations = location_getter.get_object_locations()
		
		for location in object_locations:
			var new_object = load(object["scene"]).instantiate()
			new_object.position = location
			fresh_scenes[object_name].add_child(new_object)


func override_apply():
	for child in get_children():
		child.free()
	
	for scene in fresh_scenes.values():
		add_child(scene)
