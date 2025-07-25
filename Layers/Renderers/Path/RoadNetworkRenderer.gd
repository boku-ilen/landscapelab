extends LayerCompositionRenderer
class_name RoadNetworkRenderer

var road_layer: GeoFeatureLayer
var intersection_layer: GeoFeatureLayer

var chunks = []
var chunk_size = 1000.0
var step_size = chunk_size / (200.0)

var render_3d = false

var radius: float = 2000.0
var max_features = 5000

var _road_instance_scene = preload("res://Layers/Renderers/Path/Roads/RoadInstance.tscn")
var _intersection_instance_scene = preload("res://Layers/Renderers/Path/Roads/Intersections/IntersectionInstance.tscn")
var heightmap_data_arrays: Dictionary = {}

var roads = {}
var roads_to_add = {}
var roads_to_delete = {}

var intersections = {}
var intersections_to_add = {}
var intersections_to_delete = {}

var chunk_dict = {}
const TERRAFORMING_FALLOFF = 3


func _ready():
	super._ready()
	
	road_layer = layer_composition.render_info.road_roads
	intersection_layer = layer_composition.render_info.road_intersections


func is_new_loading_required(position_diff: Vector3) -> bool:
	if Vector2(position_diff.x, position_diff.z).length_squared() >= pow(radius / 4.0, 2):
		return true
	
	return false


func full_load():
	load_data()


func adapt_load(diff):
	super.adapt_load(diff)
	load_data()


func load_data() -> void:
	## Create dictionary for height lookup
	#_create_heightmap_dictionary()
	
	# Get road data from db
	var player_position = [int(center[0] + get_parent().position_manager.center_node.position.x), int(center[1] - get_parent().position_manager.center_node.position.z)]
	var road_features = road_layer.get_features_near_position(float(player_position[0]), float(player_position[1]), radius, max_features)
	#var intersection_features = intersection_layer.get_features_near_position(float(player_position[0]), float(player_position[1]), radius, max_features)

	_create_roads(road_features)
	
	#if render_3d:
		## Set the new terraforming textures in the chunk
		#for chunk in chunks:
			#chunk.terraforming_texture.update_texture()
			#chunk.apply_terraforming_texture()
	#
	
	#_create_intersections(intersection_features)
	apply_new_data.call_deferred()


# Creates and fills the dictionary with the chunk-heightmaps using their position as keys
func _create_heightmap_dictionary() -> void:
	heightmap_data_arrays.clear()
	chunk_dict.clear()
	for chunk in chunks:
		var position_x = roundi(chunk.position.x / chunk_size)
		var position_z = roundi(chunk.position.z / chunk_size)
		if heightmap_data_arrays.has(position_x):
			heightmap_data_arrays[position_x][position_z] = chunk.current_heightmap.get_image().get_data().duplicate()
			chunk_dict[position_x][position_z] = chunk
		else:
			heightmap_data_arrays[position_x] = {position_z: chunk.current_heightmap.get_image().get_data().duplicate()}
			chunk_dict[position_x] = {position_z: chunk}


func _create_roads(road_features) -> void:
	roads_to_delete = roads.duplicate()
	roads_to_add.clear()
	
	for road_feature in road_features:
		# FIXME: Must be "road_id" attribute for intersections logic
		var road_id: int = int(road_feature.get_id())
		
		# Skip if road is already loaded
		if roads.has(road_id):
			roads_to_delete.erase(road_id)
			continue
		
		# Get point curve from feature
		var road_curve: Curve3D = road_feature.get_offset_curve3d(-center[0] - position_manager.center_node.position.x, 0, -center[1] + position_manager.center_node.position.z)
		var road_instance: RoadInstance = _road_instance_scene.instantiate()
		road_instance.position.x = position_manager.center_node.position.x
		road_instance.position.z = position_manager.center_node.position.z
		road_instance.id = road_id
		
		# Get road data
		var road_width = float(road_feature.get_attribute("width"))
		
		# FIXME: Could be done in a more general way
		# We check whether this feature contains rails, because rails are
		#  rendered in 3D -> we need heights
		var point_count = road_curve.get_point_count()
		
		var first_point = road_curve.get_point_position(0)
		var last_point = road_curve.get_point_position(road_curve.get_point_count() - 1)
		var length = road_curve.get_baked_length()
		
		var height_at_first = layer_composition.render_info.height_layer.get_value_at_position(position_manager.center_node.position.x + center[0] + first_point.x, -position_manager.center_node.position.z + center[1] - first_point.z)
		var height_at_last = layer_composition.render_info.height_layer.get_value_at_position(position_manager.center_node.position.x + center[0] + last_point.x, -position_manager.center_node.position.z + center[1] - last_point.z)
		
		for index in range(point_count):
			var point = road_curve.get_point_position(index)
			
			if road_feature.get_attribute("bridge") == "1":
				var lerp_factor = first_point.distance_to(Vector3(point.x, 0.0, point.z)) / length
				point.y = lerp(height_at_first, height_at_last, lerp_factor) + 0.1
			else:
				point.y = get_basic_height(point)
			
			road_curve.set_point_position(index, point)
		
		road_instance.road_curve = road_curve
		roads[road_id] = road_instance
		roads_to_add[road_id] = road_instance
		
		road_instance.load_from_feature(road_feature)


func _create_intersections(intersection_features) -> void:
	intersections_to_delete = intersections.duplicate()
	intersections_to_add.clear()
	
	for intersection_feature in intersection_features:
		var intersection_id: int = int(intersection_feature.get_attribute("intersection_id"))
		# Skip if intersection is already loaded
		if intersections.has(intersection_id):
			intersections_to_delete.erase(intersection_id)
			continue
		
		var intersection_instance: IntersectionInstance = _intersection_instance_scene.instantiate()
		
		var valid_intersection = intersection_instance.load_from_feature(intersection_feature, roads)
		
		if not valid_intersection:
			intersection_instance.queue_free()
			continue
		
		intersections[intersection_id] = intersection_instance
		intersections_to_add[intersection_id] = intersection_instance
		
		intersection_instance.update_intersection()


func apply_new_data() -> void:
	super.apply_new_data()
	
	# Delete old roads
	for road_id in roads_to_delete.keys():
		roads.erase(road_id)
		roads_to_delete[road_id].queue_free()
		roads_to_delete.erase(road_id)
	
	## Delete old intersections
	#for intersection_id in intersections_to_delete.keys():
		#intersections.erase(intersection_id)
		#intersections_to_delete[intersection_id].queue_free()
	
	# Add new roads
	for road in roads_to_add.values():
		$Roads.add_child(road)
		road.update_road_lanes()
	roads_to_add.clear()
	
	## Add new intersections
	#for intersection in intersections_to_add.values():
		#$Intersections.add_child(intersection)
	#intersections_to_add.clear()


# Returns the triangle surface point at the given point-position
func get_triangular_interpolation_point(point: Vector3, step_size: float) -> Vector3:
	var A = QuadUtil.get_lower_left_point(point, step_size)
	var C = QuadUtil.get_upper_right_point(point, step_size)
	var B
	
	# Check if point is in upper half of the triangle
	if fposmod(point.x, step_size) + fposmod(point.z, step_size) < step_size:
		B = QuadUtil.get_upper_left_point(point, step_size)
	else:
		B = QuadUtil.get_lower_right_point(point, step_size)
	
	# Get barycentric weights
	var weights = QuadUtil.triangular_interpolation(point, A, B, C)
	# Calculate triangle surface point with weights
	point.y = _get_height(A) * weights.x + _get_height(B) * weights.y + _get_height(C) * weights.z
	return point


func get_basic_height(point: Vector3) -> float:
	var coords = position_manager.to_world_coordinates(point)
	coords.x += position_manager.center_node.position.x
	coords.z -= position_manager.center_node.position.z
	
	return layer_composition.render_info.height_layer.get_value_at_position(coords.x, coords.z)


func _get_height(point: Vector3) -> float:
	# Get chunk
	var chunk_x: int = roundi(point.x / chunk_size)
	var chunk_z: int = roundi(point.z / chunk_size)
	var data: PackedByteArray = heightmap_data_arrays[chunk_x][chunk_z]
	
	var image_size = 201
	
	var corrected_pos_x = point.x - chunk_x * chunk_size
	var corrected_pos_z = point.z - chunk_z * chunk_size
	
	var image_x = floori(((corrected_pos_x + chunk_size / 2.0) / chunk_size) * image_size)
	var image_y = floori(((corrected_pos_z + chunk_size / 2.0) / chunk_size) * image_size)
	
	var image_position := _image_xy_to_index(image_x, image_y, image_size)
	
	# Read bytes from image
	var value: float = data.decode_float(image_position * 4)
	
	return value


func _image_xy_to_index(image_x, image_y, image_size) -> int:
	image_x = clamp(image_x, 0, image_size - 1)
	image_y = clamp(image_y, 0, image_size - 1)
	
	return image_y * image_size + image_x


func _set_terraforming_height(point: Vector3, road_width: float) -> void:
	# Get chunk
	var chunk_x: int = roundi(point.x / chunk_size)
	var chunk_z: int = roundi(point.z / chunk_size)
	var chunk: TerrainChunk = chunk_dict[chunk_x][chunk_z]
	
	var image_size = 201
	
	var corrected_pos_x = point.x - chunk_x * chunk_size
	var corrected_pos_z = point.z - chunk_z * chunk_size
	
	var image_x = floori(((corrected_pos_x + chunk_size / 2.0) / chunk_size) * image_size)
	var image_y = floori(((corrected_pos_z + chunk_size / 2.0) / chunk_size) * image_size)
	
	var image_position := _image_xy_to_index(image_x, image_y, image_size)
	
	var required_points = ceili(road_width / step_size) + 2
	# Make sure the number is odd to avoid artifacts due to uneven extends to left and right
	if not required_points & 1:
		required_points += 1
	
	for i in range(required_points):
		var offset: int = i - floori(required_points / 2.0)
		
		chunk.terraforming_texture.set_pixel(
			_image_xy_to_index(image_x + offset, image_y, image_size), point.y, 1.0)
		chunk.terraforming_texture.set_pixel(
			_image_xy_to_index(image_x, image_y + offset, image_size), point.y, 1.0)
	
	var required_points_offset = floori(required_points / 2.0)
	for i in range(TERRAFORMING_FALLOFF):
		var weight = 1.0 - float(i + 1) / float(TERRAFORMING_FALLOFF + 1)
		# X-Axis left
		var new_x_left = _image_xy_to_index(image_x - (required_points_offset + i + 1), image_y, image_size)
		chunk.terraforming_texture.set_pixel(new_x_left, point.y, weight)
		# X-Axis right
		var new_x_right = _image_xy_to_index(image_x + (required_points_offset + i + 1), image_y, image_size)
		chunk.terraforming_texture.set_pixel(new_x_right, point.y, weight)
		# Z-Axis up
		var new_z_up = _image_xy_to_index(image_x, image_y - (required_points_offset + i + 1), image_size)
		chunk.terraforming_texture.set_pixel(new_z_up, point.y, weight)
		# Z-Axis down
		var new_z_down = _image_xy_to_index(image_x, image_y + (required_points_offset + i + 1), image_size)
		chunk.terraforming_texture.set_pixel(new_z_down, point.y, weight)
