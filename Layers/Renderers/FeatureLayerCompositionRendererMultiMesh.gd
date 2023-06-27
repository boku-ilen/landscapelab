extends LayerCompositionRenderer
class_name FeatureLayerCompositionRendererMultiMesh


# Define variables for loading features
var mutex = Mutex.new()
var features := []
var instances := {}
var radius = 6000.0
var max_features = 2000
var instance_count = 11519
var aabb_vec := Vector4(INF, INF, -INF, -INF)
@onready var multimesh: MultiMesh = $MultiMeshInstance3D.multimesh

var remove_features := []
var load_features := []

signal feature_instance_removed(id: int)


func _ready():
	super._ready()
	$MultiMeshInstance3D.set_custom_aabb(AABB(Vector3.ONE * -40000, Vector3.ONE * 40000))
	
	multimesh.instance_count = instance_count


func full_load():
	features = layer_composition.render_info.geo_feature_layer.get_features_near_position(
		float(center[0]), float(center[1]), radius, max_features)
	
	mutex.lock()
	for feature in features:
		instances[feature.get_id()] = load_feature_instance(feature)
	mutex.unlock()


func adapt_load(_diff: Vector3):
	mutex.lock()
	var new_features = layer_composition.render_info.geo_feature_layer.get_features_near_position(
		float(center[0]) + position_manager.center_node.position.x,
		float(center[1]) - position_manager.center_node.position.z,
		radius, max_features
	)
	
	var old_feature_ids = features.map(func(f): return f.get_id())
	var new_feature_ids = new_features.map(func(f): return f.get_id())
	
	remove_features = features.filter(func(f): return not f.get_id() in new_feature_ids)
	load_features = new_features.filter(func(f): return not f.get_id() in old_feature_ids)
	
	features = new_features
	
	for feature in load_features:
		instances[feature.get_id()] = load_feature_instance(feature)
	
	mutex.unlock()
	
	call_deferred("apply_new_data")


func apply_new_data():
	mutex.lock()
	# Set the instance count to all cummulated vertecies
	var intermediate_transforms = calculate_intermediate_transforms()
	
	multimesh.instance_count = features.reduce(
		func(i, f): return i + f.get_curve3d().get_point_count(), 0) + intermediate_transforms.size()
	
	var current_index := 0
	for feature in features:
		current_index = apply_feature_instance(feature, current_index)
	
	for t in intermediate_transforms:
		multimesh.set_instance_transform(current_index, t)
		current_index += 1
	
	build_aabb()
	mutex.unlock()
	
	super.apply_new_data()
	
	logger.info("Applied new feature data for %s" % [name])


# Might be necessary to be overwritten by inherited class
# Apply feature to the main scene - not run in a thread
func apply_feature_instance(feature: GeoFeature, current_index: int):
	mutex.lock()
	if instances.has(feature.get_id()) and instances[feature.get_id()] != null:
		var vertices: Curve3D = feature.get_curve3d()
		for vert_id in vertices.get_point_count():
			var t: Transform3D = instances[feature.get_id()].get_child(vert_id).transform
			multimesh.set_instance_custom_data(current_index, Color(0,0,feature.get_id(),vert_id))
			multimesh.set_instance_transform(current_index, t)
			current_index += 1
	else:
		logger.error("No feature instance was created for ID: {}".
			format([feature.get_id()], "{}"))
	
	mutex.unlock()
	
	return current_index


func count_intermediate():
	pass


func calculate_intermediate_transforms():
	var get_feature_child = func(f_id, v_id):
		return instances[f_id].get_child(v_id)
	
	var transforms := []
	for feature in features:
		var f_id = feature.get_id()
		var vertices: Curve3D = feature.get_curve3d()
		var starting_point: Vector3 = get_feature_child.call(f_id, 0).position
		var end_point: Vector3
		var get_ground_height_at_pos = layer_composition.render_info.ground_height_layer.get_value_at_position
		
		var t: Transform3D
		for v_id in range(1, vertices.get_point_count()):
			t = get_feature_child.call(f_id, v_id).transform
			end_point = get_feature_child.call(f_id, v_id).position
			
			var distance = starting_point.distance_to(end_point)
			var width = 0.8
			var num_between = ceil(distance / width)
			var direction = end_point.direction_to(starting_point)
			
			t.basis.z = -direction
			
			var rand_angle := 0.0
			for i in range(num_between):
				var pos = t.origin + width * direction
				# Randomly add 90, 180 or 270 degrees to previous rotation
				var pseudo_random = int(pos.x + pos.z)
				rand_angle = rand_angle + (PI / 2.0) * ((pseudo_random % 3) + 1.0)
				t = t.rotated_local(Vector3.UP, rand_angle)
				t.origin = pos
				
				# Set the mesh on ground and add some buffer for uneven grounds
				t.origin.y = get_ground_height_at_pos.call(
					center[0] + t.origin.x, center[1] - t.origin.z) - 0.2 
				
				transforms.append(t)
			
			starting_point = end_point
	
	return transforms


# To be implemented by inherited class
# Instantiate and initially configure (e.g. set position) of  the instance - run in a thread
# Append instances to dictionary
func load_feature_instance(feature: GeoFeature) -> Node3D:
	return Node3D.new()


func build_aabb():
	aabb_vec = Vector4(INF, INF, -INF, -INF)
	
	var height_at_pos = layer_composition.render_info.ground_height_layer.get_value_at_position
	
	for feature in features:
		for vert_id in feature.get_curve3d().get_point_count():
			var t: Transform3D = instances[feature.get_id()].get_child(vert_id).transform
			aabb_vec.x = min(aabb_vec.x, t.origin.x)
			aabb_vec.y = min(aabb_vec.y, t.origin.z)
			aabb_vec.z = max(aabb_vec.z, t.origin.x)
			aabb_vec.w = max(aabb_vec.w, t.origin.z)
	
	if aabb_vec != Vector4(INF, INF, -INF, -INF):
		var begin = Vector3(aabb_vec.x, 0, aabb_vec.y)
		var end = Vector3(aabb_vec.z, 0, aabb_vec.w)
		begin.y = height_at_pos.call(center[0] + begin.x, center[1] - begin.z) - 30
		end.y = height_at_pos.call(center[0] + begin.x, center[1] - begin.z) + 30
		var size = abs(end - begin)
		$MultiMeshInstance3D.set_custom_aabb(AABB(begin, size))


func is_new_loading_required(position_diff: Vector3) -> bool:
	if Vector2(position_diff.x, position_diff.z).length_squared() >= pow(radius / 4.0, 2):
		return true
	
	return false
