extends Node3D
class_name PathRenderer

var path_layer: GeoFeatureLayer

var chunks = []
var chunk_size = 1000.0

var center = [0,0]
var radius: float = 500.0
var max_features = 1000

var _path_instance_scene = preload("res://Layers/Renderers/Path/PathInstance.tscn")
var heightmaps: Dictionary = {}


func load_roads() -> void:
	_create_heightmap_dictionary()
	
	var path_features = path_layer.get_features_near_position(float(center[0]), float(center[1]), radius, max_features)
	for path_feature in path_features:
		var path = _create_path(path_feature)


func _create_heightmap_dictionary() -> void:
	for chunk in chunks:
		var position_x = int(chunk.position.x / 1000)
		var position_z = int(chunk.position.z / 1000)
		if heightmaps.has(position_x):
			heightmaps[position_x][position_z] = chunk.current_heightmap.duplicate()
		else:
			heightmaps[position_x] = {position_z: chunk.current_heightmap.duplicate()}


func _create_path(path_feature) -> PathInstance:
	var path_instance: PathInstance
	
	var path_curve: Curve3D = path_feature.get_offset_curve3d(-center[0], 0, -center[1])
	for index in range(path_curve.point_count):
		var position = path_curve.get_point_position(index)
		var height = _get_height(position)
		var cube: MeshInstance3D = $"../MeshInstance3D".duplicate()
		cube.position = position
		cube.position.y = height
		add_child(cube)
	
	return path_instance


func _get_height(position: Vector3) -> float:
	# Get chunk
	var chunk_x: int = position.x / 1000.0
	var chunk_z: int = position.z / 1000.0
	var heightmap: ImageTexture = heightmaps[chunk_x][chunk_z]
	var image_size = heightmap.get_width()
	
	var image_x = int(((fposmod(position.x + chunk_size / 2.0, chunk_size)) / chunk_size) * image_size)
	var image_y = int(((fposmod(position.z + chunk_size / 2.0, chunk_size)) / chunk_size) * image_size)
	var image_position: int = (image_y * image_size + image_x) * 4
	# Read bytes from image
	var value: float = read_from_texture(heightmap, image_position)
	
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
