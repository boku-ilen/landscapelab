extends LayerCompositionRenderer


var chunks = []

var chunk_size = 1000
var extent = 7 # extent of chunks in every direction

@export var basic_ortho_resolution := 100
@export var basic_landuse_resolution := 10
@export var basic_mesh := preload("res://Layers/Renderers/Terrain/lod_mesh_100x100.obj")
@export var basic_mesh_resolution := 100

@export var detailed_load_distance := 2000.0
@export var detailed_ortho_resolution := 2000
@export var detailed_mesh := preload("res://Layers/Renderers/Terrain/lod_mesh_200x200.obj")
@export var detailed_mesh_resolution := 200

func _ready():
	super._ready()
	for x in range(-extent, extent + 1):
		for y in range(-extent, extent + 1):
			var chunk = preload("res://Layers/Renderers/Terrain/TerrainChunk.tscn").instantiate()

			var size = chunk_size
			var chunk_position = Vector3(x * size, 0.0, y * size)

			chunk.position = chunk_position
			chunk.size = size
			
			chunk.ortho_resolution = basic_ortho_resolution
			chunk.landuse_resolution = basic_landuse_resolution
			chunk.mesh = basic_mesh
			chunk.mesh_resolution = basic_mesh_resolution
			
			chunk.height_layer = layer_composition.render_info.height_layer
			chunk.texture_layer = layer_composition.render_info.texture_layer
			chunk.landuse_layer = layer_composition.render_info.landuse_layer
			chunk.surface_height_layer = layer_composition.render_info.surface_height_layer

			chunks.append(chunk)
	
	for chunk in chunks:
		$Chunks.add_child(chunk)
	
	$PathRenderer.path_layer = layer_composition.render_info.road_edges
	$PathRenderer.chunks = chunks


func is_new_loading_required(position_diff: Vector3) -> bool:
	if abs(position_diff.x) > chunk_size or abs(position_diff.z) > chunk_size:
		return true
	else:
		return false


func full_load():
	for chunk in chunks:
		chunk.position_diff_x = 0
		chunk.position_diff_z = 0
		
		chunk.build(center[0] + chunk.position.x, center[1] - chunk.position.z)
	


func adapt_load(_diff: Vector3):
	for chunk in chunks:
		chunk.position_diff_x = 0.0
		chunk.position_diff_z = 0.0

		var changed = false

		if chunk.position.x - position_manager.center_node.position.x >= chunk_size * extent:
			chunk.position_diff_x = -chunk_size * extent * 2 - chunk_size
			changed = true
		if chunk.position.x - position_manager.center_node.position.x <= -chunk_size * extent:
			chunk.position_diff_x = chunk_size * extent * 2 + chunk_size
			changed = true
		if chunk.position.z - position_manager.center_node.position.z >= chunk_size * extent:
			chunk.position_diff_z = -chunk_size * extent * 2 - chunk_size
			changed = true
		if chunk.position.z - position_manager.center_node.position.z <= -chunk_size * extent:
			chunk.position_diff_z = chunk_size * extent * 2 + chunk_size
			changed = true
		
		if changed:
			chunk.build(center[0] + chunk.position.x + chunk.position_diff_x, center[1] - chunk.position.z - chunk.position_diff_z)
	
	call_deferred("apply_new_data")


func get_nearest_chunk_below_resolution(query_position: Vector3, resolution: int, max_distance: float):
	var nearest_distance = INF
	var nearest_chunk
	
	for chunk in chunks:
		if chunk.ortho_resolution < resolution:
			var distance = chunk.position.distance_to(query_position)
			if distance < nearest_distance and distance < max_distance:
				nearest_distance = distance
				nearest_chunk = chunk
	
	return nearest_chunk

var load_roads = false
func refine_load():
	var any_change_done = false
	
	# Downgrade chunks which are now too far away
	for chunk in chunks:
		if chunk.ortho_resolution >= detailed_ortho_resolution and \
				chunk.position.distance_to(position_manager.center_node.position) > detailed_load_distance:
			chunk.position_diff_x = 0
			chunk.position_diff_z = 0
		
			chunk.mesh = basic_mesh
			chunk.mesh_resolution = basic_mesh_resolution
			chunk.ortho_resolution = basic_ortho_resolution
			chunk.build(center[0] + chunk.position.x + chunk.position_diff_x,
				center[1] - chunk.position.z - chunk.position_diff_z)
			chunk.changed = true
			any_change_done = true
	
	# Upgrade nearby chunks
	var nearest_chunk = get_nearest_chunk_below_resolution(position_manager.center_node.position, detailed_ortho_resolution, detailed_load_distance)
	
	if nearest_chunk:
		load_roads = true
		nearest_chunk.position_diff_x = 0
		nearest_chunk.position_diff_z = 0
		
		nearest_chunk.mesh = detailed_mesh
		nearest_chunk.mesh_resolution = detailed_mesh_resolution
		nearest_chunk.ortho_resolution = detailed_ortho_resolution
		
		nearest_chunk.build(center[0] + nearest_chunk.position.x + nearest_chunk.position_diff_x,
			center[1] - nearest_chunk.position.z - nearest_chunk.position_diff_z)
		nearest_chunk.changed = true
		any_change_done = true
	elif load_roads:
		load_roads = false
		$PathRenderer.center = center
		$PathRenderer.call_deferred("load_roads")
	
	if any_change_done:
		call_deferred("apply_new_data")


func apply_new_data():
	for chunk in $Chunks.get_children():
		if chunk.changed:
			chunk.position.x += chunk.position_diff_x
			chunk.position.z += chunk.position_diff_z
			
			chunk.apply_textures()
	
	logger.info("Applied new RealisticTerrainRenderer data for %s" % [name], LOG_MODULE)


func get_debug_info() -> String:
	return "{0} chunks with a maximum size of {1} m.".format([
		chunks.size(),
		chunks.back().size
	])
