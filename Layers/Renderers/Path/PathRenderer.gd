extends Node3D
class_name PathRenderer

var path_layer: GeoFeatureLayer

var chunks = []
var chunk_size = 1000.0
var step_size = chunk_size / (300.0)

var center = [0,0]
var radius: float = 500.0
var max_features = 1000

var _road_instance_scene = preload("res://Layers/Renderers/Path/Roads/RoadInstance.tscn")
var heightmap_data_arrays: Dictionary = {}

var roads_parent: Node3D
var roads = []

# DEBUGGING
var draw_debug_points: bool = true
var debug_point_scene = preload("res://Layers/Renderers/Path/Roads/RoadDebugPoint.tscn")
var debug_point2_scene = preload("res://Layers/Renderers/Path/Roads/RoadDebugPoint2.tscn")
var debug_points_parent: Node3D

func load_roads() -> void:
	# Variables are now unlinked to scene object (allows deletion of old and adding  of new objects)
	roads_parent = Node3D.new()
	roads_parent.name = "Roads"
	
	debug_points_parent = Node3D.new()
	debug_points_parent.name = "Debug"
	
	
	_create_heightmap_dictionary()
	var player_position = [int(center[0] + $"..".position_manager.center_node.position.x), int(center[1] - $"..".position_manager.center_node.position.z)]
	var path_features = path_layer.get_features_near_position(float(player_position[0]), float(player_position[1]), radius, max_features)
	_create_roads(path_features)
	
	call_deferred("_add_objects")


# Creates and fills the dictionary with the chunk-heightmaps using their position as keys
func _create_heightmap_dictionary() -> void:
	heightmap_data_arrays.clear()
	for chunk in chunks:
		var position_x = roundi(chunk.position.x / chunk_size)
		var position_z = roundi(chunk.position.z / chunk_size)
		if heightmap_data_arrays.has(position_x):
			heightmap_data_arrays[position_x][position_z] = chunk.current_heightmap.get_image().get_data().duplicate()
		else:
			heightmap_data_arrays[position_x] = {position_z: chunk.current_heightmap.get_image().get_data().duplicate()}


func _create_roads(road_features) -> void:
	for road_feature in road_features:
		var road_type: String = road_feature.get_attribute("type")
		
		# Skip all rail-roads
		if road_type.begins_with('E'):
			continue
		
		# Get point curve from feature
		var road_curve: Curve3D = road_feature.get_offset_curve3d(-center[0], 0, -center[1])
		
		var road_instance: RoadInstance = _road_instance_scene.instantiate()
		
		roads_parent.add_child(road_instance)
		
		
		# SET INITIAL POINT HEIGHTS
		var point_count = road_curve.get_point_count()
		for index in range(point_count):
			# Make sure all roads are facing up
			#road_curve.set_point_tilt(index, 0)

			var point = road_curve.get_point_position(index)
			point = get_triangular_interpolation_point(point, step_size)
			road_curve.set_point_position(index, point)
			
			if draw_debug_points:
				var debug_point: MeshInstance3D = debug_point_scene.instantiate()
				debug_point.position = point
				debug_points_parent.add_child(debug_point)
		
		# REFINE ROAD BY ADDING MESH TRIANGLE INTERSECTIONS
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
					current_point_index += 1
					
					if draw_debug_points:
						var debug_point: MeshInstance3D = debug_point2_scene.instantiate()
						debug_point.position = intersection_point
						debug_points_parent.add_child(debug_point)
				
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
					current_point = x_quad_point
					x_quad_point = null
				else:
					z_quad_point.y = _get_height(z_quad_point)
					road_curve.add_point(z_quad_point, Vector3.ZERO, Vector3.ZERO, current_point_index + 1)
					current_point = z_quad_point
					z_quad_point = null
				
				# Move to newly added point and start from there again
				current_point_index += 1
				
				if draw_debug_points:
					var debug_point: MeshInstance3D = debug_point2_scene.instantiate()
					debug_point.position = current_point
					debug_points_parent.add_child(debug_point)
				
		road_instance.curve = road_curve
		
#		road_instance.width = road_width
#		road_instance.intersection_id = int(road_feature.get_attribute("from_node"))
#		road_instance.curve.bake_interval = 2 # force recomputation
#		#road_instance.set_polygon_from_lane_uses()
		
		


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


func _get_height(position: Vector3) -> float:
	# Get chunk
	var chunk_x: int = roundi(position.x / chunk_size)
	var chunk_z: int = roundi(position.z / chunk_size)
	var data: PackedByteArray = heightmap_data_arrays[chunk_x][chunk_z]
	var image_size = 301
	
	var image_x = floori((fposmod(position.x + chunk_size / 2.0, chunk_size) / chunk_size) * image_size)
	var image_y = floori((fposmod(position.z + chunk_size / 2.0, chunk_size) / chunk_size) * image_size)
	
	var image_position: int = (image_y * image_size + image_x) * 4
	# Read bytes from image
	var value: float = data.decode_float(image_position)
	
	return value


func _add_objects() -> void:
	# Delete scene objects while keeping code objects
	$Debug.free()
	$Roads.free()
	
	add_child(roads_parent)
	add_child(debug_points_parent)
