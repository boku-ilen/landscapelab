extends RenderChunk

var height_layer: GeoRasterLayer
var object_layer: GeoFeatureLayer
var object
var randomize

var features
var fresh_multimesh

var rng := RandomNumberGenerator.new()
var initial_rng_state


func _ready():
	super._ready()
	
	rng.seed = name.hash()
	initial_rng_state = rng.state


func rebuild_aabb(node):
	var aabb = AABB(global_transform.origin - position - Vector3(size / 2.0, 0.0, size / 2.0), Vector3(size, 100000, size))
	node.set_custom_aabb(aabb)


func override_build(center_x, center_y):
	fresh_multimesh = MultiMesh.new()
	
	fresh_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	fresh_multimesh.mesh = object
	
	var top_left_x = float(center_x - size / 2)
	var top_left_y = float(center_y + size / 2)
	
	features = object_layer.get_features_in_square(top_left_x, top_left_y, size, 10000000)
	fresh_multimesh.instance_count = features.size()
	
	rng.state = initial_rng_state

	var i = 0
	for feature in features:
		var instance_scale = randf_range(0.9, 1.2) if randomize else 1.0
		var instance_rotation = -float(feature.get_attribute("LL_rot"))
		
		var pos = feature.get_offset_vector3(-int(center_x), 0, -int(center_y))
		pos.y = height_layer.get_value_at_position(pos.x + center_x, center_y - pos.z)
		
		var new_transform = Transform3D().scaled(Vector3(instance_scale, instance_scale, instance_scale))
		
		if randomize:
			new_transform = new_transform \
				.rotated(Vector3.RIGHT, rng.randi_range(0, 3) * PI * 0.5) \
				.rotated(Vector3.FORWARD, rng.randi_range(0, 3) * PI * 0.5)
		
		new_transform = new_transform \
			.rotated(Vector3.UP, deg_to_rad(instance_rotation)) \
			.translated(pos)
		
		fresh_multimesh.set_instance_transform(i, new_transform)
		
		i += 1


func override_apply():
	if fresh_multimesh.instance_count > 0:
		visible = true
	else:
		visible = false
	
	$MultiMeshInstance3D.multimesh = fresh_multimesh.duplicate()
