extends Node3D
class_name PathRenderer

var path_layer: GeoFeatureLayer

var chunks = []
var chunk_size = 1000.0
var step_size = chunk_size / (300.0 + 1.0)

var center = [0,0]
var radius: float = 500.0
var max_features = 1000

var _path_instance_scene = preload("res://Layers/Renderers/Path/PathInstance.tscn")
var heightmaps: Dictionary = {}


func load_roads() -> void:
	print("LOADING ROADS STARTED")
	for child in $"Debug".get_children():
		child.free()
	
	_create_heightmap_dictionary()
	var player_position = [int(center[0] + $"..".position_manager.center_node.position.x), int(center[1] - $"..".position_manager.center_node.position.z)]
	print("player_position: %s | %s" %[player_position[0] - center[0], player_position[1] - center[1]])
	print("Current Chunk: %s | %s" %[roundi((player_position[0] - center[0]) / 1000), roundi((player_position[1] - center[1]) / 1000)])
	var path_features = path_layer.get_features_near_position(float(player_position[0]), float(player_position[1]), radius, max_features)
	for path_feature in path_features:
		var path = _create_path(path_feature)
	
	print("LOADING ROADS FINISHED")


func _create_heightmap_dictionary() -> void:
	for chunk in chunks:
		var position_x = int(chunk.position.x / chunk_size)
		var position_z = -int(chunk.position.z / chunk_size)
		if heightmaps.has(position_x):
			heightmaps[position_x][position_z] = chunk.current_heightmap.duplicate()
		else:
			heightmaps[position_x] = {position_z: chunk.current_heightmap.duplicate()}
		
		var label: Label3D = $Label3D.duplicate()
		label.position.x = chunk.position.x
		label.position.z = chunk.position.z
		label.position.y = 200
		label.text = "[%s, %s]" %[position_x, position_z]
		$"Debug".add_child(label)


func _create_path(path_feature) -> PathInstance:
	var path_instance: PathInstance
	
	var path_curve: Curve3D = path_feature.get_offset_curve3d(-center[0], 0, -center[1])
	for index in range(path_curve.point_count):
		var position = path_curve.get_point_position(index)
		position = get_triangular_interpolation_point(position, step_size)
		#var height = _get_height(position)
		
		# DEBUGGING
		var space_state = get_parent().get_world_3d().direct_space_state
		var ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(Vector3(position.x, 6000, position.z), Vector3(position.x, -1000, position.z))
		var result = space_state.intersect_ray(ray)
		if not result.is_empty():
			var cube: MeshInstance3D = $"MeshInstance3D_test".duplicate()
			cube.position = position
			cube.position.y = result["position"].y
			$"Debug".add_child(cube)
		
		
		var cube: MeshInstance3D = $"MeshInstance3D".duplicate()
		cube.position = position
		cube.position.y = position.y
		$"Debug".add_child(cube)
	
	return path_instance


# Returns the triangle surface point at the given point-position
func get_triangular_interpolation_point(point: Vector3, step_size: float) -> Vector3:
	var A = QuadUtil.get_lower_left_point(point, step_size)
	var C = QuadUtil.get_upper_right_point(point, step_size)
	var B
	
	# Check if point is in upper half of the triangle
	if fposmod(point.x, step_size) < fposmod(point.z, step_size):
		B = QuadUtil.get_lower_right_point(point, step_size)
	else:
		B = QuadUtil.get_upper_left_point(point, step_size)
	
	# Get barycentric weights
	var weights = QuadUtil.triangular_interpolation(point, A, B, C)
	# Calculate triangle surface point with weights
	point.y = _get_height(A) * weights.x + _get_height(B) * weights.y + _get_height(C) * weights.z
	return point


func _get_height(position: Vector3) -> float:
	# Get chunk
	var chunk_x: int = int(position.x / chunk_size)
	var chunk_z: int = int(position.z / chunk_size)
	var heightmap: ImageTexture = heightmaps[chunk_x][chunk_z]
	var image_size = heightmap.get_width()
	
	#var image_x = roundi(((fposmod(position.x + chunk_size / 2.0, chunk_size)) / chunk_size) * image_size)
	#var image_y = roundi(((fposmod(position.z + chunk_size / 2.0, chunk_size)) / chunk_size) * image_size)
	
	var image_x = int((fposmod(position.x + chunk_size / 2.0, chunk_size) / chunk_size) * image_size)
	var image_y = int((fposmod(-position.z + chunk_size / 2.0, chunk_size) / chunk_size) * image_size)
	
	var image_position: int = (image_y * image_size + image_x) * 4
	# Read bytes from image
	var value: float = read_from_texture(heightmap, image_position)
	if value < 1.0:
		print("No height decoded")
	
	return value


static func read_from_texture(texture: ImageTexture, pos: int) -> float:
	return texture.get_image().get_data().decode_float(pos)


static func bytes_to_vector(bytes: PackedByteArray) -> Vector2:
	var vector_bytes: PackedByteArray
	# Vector2 header
	vector_bytes.append(5)
	vector_bytes.append(0)
	vector_bytes.append(0)
	vector_bytes.append(0)
	# height as 32-bit float
	vector_bytes.append_array(bytes)
	# zero as 32-bit float
	vector_bytes.append(0)
	vector_bytes.append(0)
	vector_bytes.append(0)
	vector_bytes.append(0)
	# Reconstruct vector from bytes
	return bytes_to_var(vector_bytes)
