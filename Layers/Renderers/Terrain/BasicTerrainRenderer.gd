extends LayerCompositionRenderer


var chunks = []

var chunk_size = 1000
var extent = 5

@export var basic_texture_resolution := 1000
@export var basic_mesh := preload("res://Layers/Renderers/Terrain/lod_mesh_100x100.obj")
@export var basic_mesh_resolution := 100


func _ready():
	super._ready()
	for x in range(-extent, extent + 1):
		for y in range(-extent, extent + 1):
			var chunk = preload("res://Layers/Renderers/Terrain/BasicTerrainChunk.tscn").instantiate()

			var size = chunk_size
			var chunk_position = Vector3(x * size, 0.0, y * size)

			chunk.position = chunk_position
			chunk.size = size
			
			chunk.texture_resolution = basic_texture_resolution
			chunk.mesh = basic_mesh
			chunk.mesh_resolution = basic_mesh_resolution
			
			chunk.height_layer = layer_composition.render_info.height_layer
			chunk.texture_layer = layer_composition.render_info.texture_layer

			chunks.append(chunk)
	
	for chunk in chunks:
		$Chunks.add_child(chunk)


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
	super.adapt_load(_diff)
	
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


func apply_new_data():
	for chunk in $Chunks.get_children():
		if chunk.changed:
			chunk.position.x += chunk.position_diff_x
			chunk.position.z += chunk.position_diff_z
			
			chunk.apply_textures()
	
	logger.info("Applied new RealisticTerrainRenderer data for %s" % [name])


func get_debug_info() -> String:
	return "{0} chunks with a maximum size of {1} m.".format([
		chunks.size(),
		chunks.back().size
	])
