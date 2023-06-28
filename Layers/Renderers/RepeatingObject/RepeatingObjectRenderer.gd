extends FeatureLayerCompositionRendererMultiMesh


#
# Repeated objects along a line - can be used for e.g. Hedges
# Objects will be placed with predefined width from one another
#
# Notes:
# - To remove the repetitiveness of the mesh it will be randomly rotated
# - Extends the multimesh feature layer to drastically improve performance
#


var multimeshes := {}


func _ready():
	mutex.lock()
	_load_meshes()
	mutex.unlock()
	super._ready()
	max_features = 500
	radius = 120.0


func _load_meshes():
	# FIXME: Does adding multiple multimeshes drastically decrease performance?
	# FIXME: If so use different custom data and read according texture in shader 
	for key in layer_composition.render_info.meshes.keys():
		var multimesh_instance = MultiMeshInstance3D.new()
		multimesh_instance.multimesh = MultiMesh.new()
		multimesh_instance.multimesh.set_transform_format(MultiMesh.TRANSFORM_3D)
		multimesh_instance.multimesh.mesh = load(layer_composition.render_info.meshes[key])
		multimesh_instance.set_layer_mask_value(1, false)
		multimesh_instance.set_layer_mask_value(3, true)
		multimeshes[key] = multimesh_instance
		add_child(multimesh_instance)


func apply_new_data():
	mutex.lock()
	# Set the instance count to all cummulated vertecies
	var intermediate_transforms = _calculate_intermediate_transforms()
	
	# Reset
	var attribute_name = layer_composition.render_info.selector_attribute_name
	var compare_type = func(type: String, f: GeoFeature): 
		return f.get_attribute(attribute_name) == type
	
	var indices = {}
	for key in layer_composition.render_info.meshes.keys():
		var filtered_features = features.filter(func(f): return compare_type.call(key, f))
		
		var instance_count = filtered_features.reduce(func(accum, f):
			return accum + intermediate_transforms[f.get_id()].size(), 0
		)

		multimeshes[key].multimesh.instance_count = instance_count
		indices[key] = 0
	
	for f in features:
		for t in intermediate_transforms[f.get_id()]:
			var type = f.get_attribute(attribute_name)
			multimeshes[type].multimesh.set_instance_transform(indices[type], t)
			indices[type] += 1
	
	build_aabb(intermediate_transforms)
	mutex.unlock()
	
	super.apply_new_data()


func build_aabb(transforms):
	var begin = Vector3(INF, INF, INF)
	var end = Vector3(-INF, -INF, -INF)
	
	var height_at_pos = layer_composition.render_info.ground_height_layer.get_value_at_position
	
	for key in transforms:
		for t in transforms[key]:
			begin.x = min(begin.x, t.origin.x)
			begin.y = min(begin.y, t.origin.y)
			begin.z = min(begin.z, t.origin.z)
			end.x = max(end.x, t.origin.x)
			end.y = max(end.y, t.origin.y)
			end.z = max(end.z, t.origin.z)
	
	begin.y -= 10
	end.y += 10
	var size = abs(end - begin)
	
	for multimesh in multimeshes.values():
		multimesh.set_custom_aabb(AABB(begin, size))


# Although we use a multimesh, we load the transforms via nodes as they drastically
# simplify some matrix calculations
# FIXME: clean this up
func load_feature_instance(geo_line: GeoFeature) -> Node3D:
	return Node3D.new()


func _calculate_intermediate_transforms():
	var transforms := {}
	for feature in features:
		var f_id = feature.get_id()
		var vertices: Curve3D = feature.get_offset_curve3d(-center[0], 0, -center[1])
		var starting_point: Vector3
		var end_point: Vector3
		var get_ground_height_at_pos = layer_composition.render_info.ground_height_layer.get_value_at_position
		
		var t: Transform3D
		transforms[f_id] = []
		for v_id in range(1, vertices.get_point_count()):
			starting_point = vertices.get_point_position(v_id - 1)
			t = Transform3D(Basis.IDENTITY, starting_point)
			end_point = vertices.get_point_position(v_id)
			
			var distance = starting_point.distance_to(end_point)
			var width = layer_composition.render_info.width
			var num_between = ceil(distance / width)
			var scaled_width = distance / num_between
			var scale_factor = scaled_width / width
			
			var direction = starting_point.direction_to(end_point)
			direction.y = 0
			
			t.basis.z = direction.normalized()
			t.basis.y = Vector3.UP
			t.basis.x = t.basis.y.cross(t.basis.z)
			
			t = t.scaled_local(Vector3(1, 1, scale_factor))
			
			var rand_angle := 0.0
			for i in range(num_between):
				var pos = t.origin + direction.normalized() * scaled_width
				# Randomly add 90, 180 or 270 degrees to previous rotation
				if layer_composition.render_info.random_angle:
					var pseudo_random = int(pos.x + pos.z)
					rand_angle = rand_angle + (PI / 2.0) * ((pseudo_random % 3) + 1.0)
					t = t.rotated_local(Vector3.UP, rand_angle)
				t.origin = pos #* Vector3(1, 1, scale_factor)
				
				# Set the mesh on ground and add some buffer for uneven grounds
				t.origin.y = get_ground_height_at_pos.call(
					center[0] + t.origin.x, center[1] - t.origin.z)
				
#				if i == num_between - 1 and num_between > 1:
#					t.basis.z = -t.basis.z
				
				transforms[f_id].append(t)
			
			starting_point = end_point
	
	return transforms


# https://github.com/godotengine/godot/blob/4.0.1-stable/scene/resources/curve.cpp#L1784
# avoid "look_at_from_position: Node origin and target are in the same position, look_at() failed."
func try_look_at_from_pos(object: Node3D, from: Vector3, target: Vector3):
	if not from.is_equal_approx(target) and not target.is_equal_approx(Vector3.ZERO):
		object.position = from
		object.look_at_from_position(from, target, object.transform.basis.y)
	else:
		object.position = from
		object.look_at(target, object.transform.basis.y)


func _get_height_at_ground(query_position: Vector3) -> float:
	return layer_composition.render_info.ground_height_layer.get_value_at_position(
		center[0] + query_position.x, center[1] - query_position.z)


func get_debug_info() -> String:
	return ""
