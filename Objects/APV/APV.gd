tool
extends Spatial


export(PackedScene) var apv_scene
export var apv_rotation := -90.0

export var extent_x := 100
export var extent_z := 100

export var distance_x := 10.0
export var distance_z := 20.0

var center
var height_layer
var height_already_set = false


func _ready():
	for offset_x in range(-extent_x / 2.0, extent_x / 2.0, distance_x):
		for offset_z in range(-extent_z / 2.0, extent_z / 2.0, distance_z):
			var instance = apv_scene.instance()
			instance.rotation_degrees.y = apv_rotation
			
			instance.translation.x = offset_x
			instance.translation.z = offset_z
			
			add_child(instance)


func set_height(origin):
	if height_already_set: return
	
	for child in get_children():
		var pos_x = center[0] + origin.x + child.translation.x
		var pos_y = center[1] - origin.z - child.translation.z
		var height = height_layer.get_value_at_position(pos_x, pos_y)
		
		child.translation.y = height
	
	height_already_set = true
