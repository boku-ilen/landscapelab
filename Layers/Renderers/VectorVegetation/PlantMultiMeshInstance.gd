extends MultiMeshInstance3D


var size: float

var position_diff_x
var position_diff_z
var changed := false

var height_layer: GeoRasterLayer
var plant_layer: GeoFeatureLayer

var new_multimesh

func rebuild_aabb():
	var aabb = AABB(global_transform.origin - position - Vector3(size / 2.0, 0.0, size / 2.0), Vector3(size, 100000, size))
	set_custom_aabb(aabb)


func load_new_data(center_x, center_y):
	var top_left_x = float(center_x - size / 2)
	var top_left_y = float(center_y + size / 2)
	
	var features = plant_layer.get_features_in_square(top_left_x, top_left_y, size, 10000000)
	new_multimesh = MultiMesh.new()
	new_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	new_multimesh.mesh = preload("res://Layers/Renderers/VectorVegetation/Spruce.tres")
	
	new_multimesh.instance_count = features.size()
	new_multimesh.visible_instance_count = new_multimesh.instance_count

	var root = sqrt(new_multimesh.visible_instance_count)
	for i in range(new_multimesh.visible_instance_count):
		var instance_scale = features[i].get_attribute("height").to_float() * 0.0015

		var pos = features[i].get_offset_vector3(-int(center_x), 0, -int(center_y))
		pos.y = height_layer.get_value_at_position(pos.x + center_x, center_y - pos.z)
		
		new_multimesh.set_instance_transform(i, Transform3D()
				.scaled(Vector3(instance_scale, instance_scale, instance_scale)) \
				.rotated(Vector3.UP, PI * 0.25 * randf()) \
				.translated(pos - Vector3.UP)
				)
	
	changed = true


func apply_new_data():
	multimesh = new_multimesh
	
	rebuild_aabb()
	
	# FIXME: nothing is visualized, but the pos.y is correct

	visible = true
	changed = false
