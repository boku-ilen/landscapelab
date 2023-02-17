extends Node3D
class_name PathRenderer

var road_layer: GeoFeatureLayer
var intersection_layer: GeoFeatureLayer

var chunks = []
var chunk_size = 1000.0
var step_size = chunk_size / (200.0)

var center = [0,0]
var radius: float = 500.0
var max_features = 1000

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

func load_data() -> void:
	var tic = Time.get_ticks_msec()
	# Create dictionary for height lookup
	_create_heightmap_dictionary()
	
	# Get road data from db
	var player_position = [int(center[0] + $"..".position_manager.center_node.position.x), int(center[1] - $"..".position_manager.center_node.position.z)]
	var road_features = road_layer.get_features_near_position(float(player_position[0]), float(player_position[1]), radius, max_features)
	var intersection_features = intersection_layer.get_features_near_position(float(player_position[0]), float(player_position[1]), radius, max_features)
	
	print(player_position)
	# Reset terrarforming textures
	for chunk in chunks:
		chunk.terrarforming_texture.reset()
	
	var toc = Time.get_ticks_msec()
	print("RoadRenderer data prep: %s" %[toc - tic])
	
	tic = Time.get_ticks_msec()
	_create_roads(road_features)
	# Set the new terrarforming textures in the chunk
	for chunk in chunks:
		chunk.terrarforming_texture.update_texture()
		chunk.apply_terrarforming_texture()
	
	for x in chunk_dict.keys():
		for z in chunk_dict[x].keys():
			chunk_dict[x][z].terrarforming_texture.save_debug_image("../Debug", "%s_%s" %[z + 7, x + 7])
	
	toc = Time.get_ticks_msec()
	print("Create Roads Time: %s" %[toc - tic])
	
	tic = Time.get_ticks_msec()
	_create_intersections(intersection_features)
	toc = Time.get_ticks_msec()
	print("Create Intersections Time: %s" %[toc - tic])
	
	call_deferred("_add_objects")


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
		var road_id: int = int(road_feature.get_attribute("road_id"))
		
		# Skip if road is already loaded
		if roads.has(road_id):
			roads_to_delete.erase(road_id)
			continue
		
		# Get point curve from feature
		var road_curve: Curve3D = road_feature.get_offset_curve3d(-center[0], 0, -center[1])
		var road_instance: RoadInstance = _road_instance_scene.instantiate()
		
		# Get road data
		var road_width = float(road_feature.get_attribute("width"))
		
		
		#############################
		# SET INITIAL POINT HEIGHTS #
		#############################
		var point_count = road_curve.get_point_count()
		for index in range(point_count):
			# Make sure all roads are facing up
			#road_curve.set_point_tilt(index, 0)

			var point = road_curve.get_point_position(index)
			point = get_triangular_interpolation_point(point, step_size)
			road_curve.set_point_position(index, point)
			_set_terraforming_height(point, road_width)
		
		#####################################################
		# REFINE ROAD BY ADDING MESH TRIANGLE INTERSECTIONS #
		#####################################################
		var current_point_index: int = 0
		
		# GO THROUGH EACH CURVE EDGE
		for index in range(point_count - 1):
			var current_point: Vector3 = road_curve.get_point_position(current_point_index)
			var next_point: Vector3 = road_curve.get_point_position(current_point_index + 1)
			
			var x_quad_point = null
			var z_quad_point = null
			
			while true:
				# INTERSECTION WITH DIAGONAL
				var intersection_point = QuadUtil.get_diagonal_intersection(current_point, next_point, step_size)
				if intersection_point != null:
					intersection_point.y = _get_height(intersection_point)
					
					# Add intersection to curve
					road_curve.add_point(intersection_point, Vector3.ZERO, Vector3.ZERO, current_point_index + 1)
					_set_terraforming_height(intersection_point, road_width)
					current_point_index += 1
				
				# INTERSECTION WITH GRID AXES
				# Only calculate grid point if we don't have one from last calculation
				if x_quad_point == null:
					x_quad_point = QuadUtil.get_horizontal_intersection(current_point, next_point, step_size)
				
				# Same for z
				if z_quad_point == null:
					z_quad_point = QuadUtil.get_vertical_intersection(current_point, next_point, step_size)
				
				# If no grid points, done with this curve edge
				if x_quad_point == null && z_quad_point == null:
					# Move to next points
					current_point_index += 1
					break
				
				# Add closest one
				if z_quad_point == null || (x_quad_point != null && current_point.distance_squared_to(x_quad_point) <= current_point.distance_squared_to(z_quad_point)):
					x_quad_point.y = _get_height(x_quad_point)
					road_curve.add_point(x_quad_point, Vector3.ZERO, Vector3.ZERO, current_point_index + 1)
					_set_terraforming_height(x_quad_point, road_width)
					current_point = x_quad_point
					x_quad_point = null
				else:
					z_quad_point.y = _get_height(z_quad_point)
					road_curve.add_point(z_quad_point, Vector3.ZERO, Vector3.ZERO, current_point_index + 1)
					_set_terraforming_height(z_quad_point, road_width)
					current_point = z_quad_point
					z_quad_point = null
				
				# Move to newly added point and start from there again
				current_point_index += 1
				
		road_instance.road_curve = road_curve
		roads[road_id] = road_instance
		roads_to_add[road_id] = road_instance
		
		road_instance.load_from_feature(road_feature)
		road_instance.update_road_lanes()


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


func _add_objects() -> void:
	# Delete old roads
	for road_id in roads_to_delete.keys():
		roads.erase(road_id)
		roads_to_delete[road_id].queue_free()
	
	# Delete old intersections
	for intersection_id in intersections_to_delete.keys():
		intersections.erase(intersection_id)
		intersections_to_delete[intersection_id].queue_free()
	
	# Add new roads
	for road in roads_to_add.values():
		$Roads.add_child(road)
	roads_to_add.clear()
	
	# Add new intersections
	for intersection in intersections_to_add.values():
		$Intersections.add_child(intersection)
	intersections_to_add.clear()


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


func _get_height(point: Vector3) -> float:
	# Get chunk
	var chunk_x: int = roundi(point.x / chunk_size)
	var chunk_z: int = roundi(point.z / chunk_size)
	var data: PackedByteArray = heightmap_data_arrays[chunk_x][chunk_z]
	var image_size = 201
	
	var image_x = floori((fposmod(point.x + chunk_size / 2.0, chunk_size) / chunk_size) * image_size)
	var image_y = floori((fposmod(point.z + chunk_size / 2.0, chunk_size) / chunk_size) * image_size)
	
	var image_position: int = (image_y * image_size + image_x)
	# Read bytes from image
	var value: float = data.decode_float(image_position * 4)
	
	return value


func _set_terraforming_height(point: Vector3, road_width: float) -> void:
	# Get chunk
	var chunk_x: int = roundi(point.x / chunk_size)
	var chunk_z: int = roundi(point.z / chunk_size)
	var chunk: TerrainChunk = chunk_dict[chunk_x][chunk_z]
	
	var image_size = 201
	var image_x = floori((fposmod(point.x + chunk_size / 2.0, chunk_size) / chunk_size) * image_size)
	var image_y = floori((fposmod(point.z + chunk_size / 2.0, chunk_size) / chunk_size) * image_size)
	var image_position: int = (image_y * image_size + image_x)
	
	var required_points = ceili(road_width / step_size) + 2
	# Make sure the number is odd to avoid artifacts due to uneven extends to left and right
	if not required_points & 1:
		required_points += 1
	
	for i in range(required_points):
		var offset: int = i - floori(required_points / 2.0)
		# X-Axis
		chunk.terrarforming_texture.set_pixel(image_position + offset, point.y, 1.0)
		# Z-Axis
		chunk.terrarforming_texture.set_pixel(image_position + (offset * image_size), point.y, 1.0)
	
	var required_points_offset = floori(required_points / 2.0)
	for i in range(TERRAFORMING_FALLOFF):
		var weight = 1.0 - float(i + 1) / float(TERRAFORMING_FALLOFF + 1)
		# X-Axis left
		chunk.terrarforming_texture.set_pixel(image_position - (required_points_offset + i + 1), point.y, weight)
		# X-Axis right
		chunk.terrarforming_texture.set_pixel(image_position + (required_points_offset + i + 1), point.y, weight)
		# Z-Axis up
		chunk.terrarforming_texture.set_pixel(image_position - ((required_points_offset + i + 1) * image_size), point.y, weight)
		# Z-Axis down
		chunk.terrarforming_texture.set_pixel(image_position + ((required_points_offset + i + 1) * image_size), point.y, weight)

