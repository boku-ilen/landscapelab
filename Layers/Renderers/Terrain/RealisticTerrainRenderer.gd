extends LayerCompositionRenderer


var chunks = []

var chunk_size = 1000
var extent = 7 # extent of chunks in every direction

var waiting_to_apply = false

@export var basic_ortho_resolution := 100
@export var basic_landuse_resolution := 100
@export var basic_mesh := preload("res://Layers/Renderers/Terrain/lod_mesh_100x100.obj")
@export var basic_mesh_resolution := 100

@export var detailed_load_distance := 2000.0
@export var detailed_ortho_resolution := 2000
@export var detailed_landuse_resolution := 1000
@export var detailed_mesh := preload("res://Layers/Renderers/Terrain/lod_mesh_500x500.obj")
@export var detailed_mesh_resolution := 500

func _ready():
	super._ready()
	
	var texture_folders = [
		"Concrete",
		"Asphalt",
		"Grass",
		"Gravel",
		"Riverbed",
		"Rock",
		"Forest",
		"Soil"
	]
	
	var color_images = []
	var normal_images = []
	
	for texture_folder in texture_folders:
		var color_image = load("res://Resources/Textures/BaseGround/" + texture_folder + "/color.jpg")
		var normal_image = load("res://Resources/Textures/BaseGround/" + texture_folder + "/normal.jpg")
		
		color_image.generate_mipmaps()
		normal_image.generate_mipmaps()
		
		color_images.append(color_image)
		normal_images.append(normal_image)
	
	var texture_array = Texture2DArray.new()
	texture_array.create_from_images(color_images)
	
	# FIXME: We'd want to save and re-use this texture, but that doesn't work due to a Godot issue:
	#  https://github.com/godotengine/godot/issues/54202
	# ResourceSaver.save(texture_array, "res://Layers/Renderers/Terrain/Materials/GroundTextures.tres")
	
	var normal_array = Texture2DArray.new()
	normal_array.create_from_images(normal_images)
	
	var shader_material = preload("res://Layers/Renderers/Terrain/Materials/TerrainShader.tres")
	shader_material.set_shader_parameter("ground_normals", normal_array)
	shader_material.set_shader_parameter("ground_textures", texture_array)
	
	for x in range(-extent, extent + 1):
		for y in range(-extent, extent + 1):
			var chunk = preload("res://Layers/Renderers/Terrain/TerrainChunk.tscn").instantiate()
			chunk.material_override = shader_material.duplicate()
			
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


func is_new_loading_required(position_diff: Vector3) -> bool:
	return not waiting_to_apply and (abs(position_diff.x) > chunk_size or abs(position_diff.z) > chunk_size)


func full_load():
	for chunk in chunks:
		chunk.position_diff_x = 0
		chunk.position_diff_z = 0
		
		chunk.build(center[0] + chunk.position.x, center[1] - chunk.position.z)


func adapt_load(_diff: Vector3):
	super.adapt_load(_diff)
	
	var player_x = position_manager.center_node.position.x
	var player_z = position_manager.center_node.position.z
	
	for chunk in chunks:
		var changed = false

		if chunk.position.x - player_x >= chunk_size * extent + chunk_size / 2.0:
			chunk.position_diff_x = -chunk_size * extent * 2 - chunk_size
			changed = true
		elif chunk.position.x - player_x <= -chunk_size * extent - chunk_size / 2.0:
			chunk.position_diff_x = chunk_size * extent * 2 + chunk_size
			changed = true
		
		if chunk.position.z - player_z >= chunk_size * extent + chunk_size / 2.0:
			chunk.position_diff_z = -chunk_size * extent * 2 - chunk_size
			changed = true
		elif chunk.position.z - player_z <= -chunk_size * extent - chunk_size / 2.0:
			chunk.position_diff_z = chunk_size * extent * 2 + chunk_size
			changed = true
		
		if changed:
			chunk.changed = true
			# Make sure the chunk is downgraded, then rebuild
			chunk.mesh = basic_mesh
			chunk.mesh_resolution = basic_mesh_resolution
			chunk.ortho_resolution = basic_ortho_resolution
			chunk.landuse_resolution = basic_landuse_resolution
			chunk.build(center[0] + chunk.position.x + chunk.position_diff_x, center[1] - chunk.position.z - chunk.position_diff_z)
	
	waiting_to_apply = true
	call_deferred("apply_new_data")


func get_nearest_chunk_below_resolution(query_position: Vector3, resolution: int, max_distance: float):
	var nearest_distance = INF
	var nearest_chunk
	
	for chunk in chunks:
		if chunk.ortho_resolution < resolution:
			var distance = Vector2(chunk.position.x, chunk.position.z).distance_to(Vector2(query_position.x, query_position.z))
			if distance < nearest_distance and distance < max_distance:
				nearest_distance = distance
				nearest_chunk = chunk
	
	return nearest_chunk


func refine_load():
	if waiting_to_apply: return
	
	super.refine_load()
	
	var any_change_done = false
	
	# Downgrade chunks which are now too far away
	for chunk in chunks:
		var distance = Vector2(chunk.position.x, chunk.position.z).distance_to(Vector2(position_manager.center_node.position.x, position_manager.center_node.position.z))
		if chunk.ortho_resolution >= detailed_ortho_resolution and \
				distance > detailed_load_distance:
			chunk.mesh = basic_mesh
			chunk.mesh_resolution = basic_mesh_resolution
			chunk.ortho_resolution = basic_ortho_resolution
			chunk.landuse_resolution = basic_landuse_resolution
			chunk.build(center[0] + chunk.position.x + chunk.position_diff_x,
				center[1] - chunk.position.z - chunk.position_diff_z)
			any_change_done = true
	
	# Upgrade nearby chunks
	var nearest_chunk = get_nearest_chunk_below_resolution(position_manager.center_node.position, detailed_ortho_resolution, detailed_load_distance)
	
	if nearest_chunk and not nearest_chunk.changed:
		nearest_chunk.mesh = detailed_mesh
		nearest_chunk.mesh_resolution = detailed_mesh_resolution
		nearest_chunk.ortho_resolution = detailed_ortho_resolution
		nearest_chunk.landuse_resolution = detailed_landuse_resolution
		
		nearest_chunk.build(center[0] + nearest_chunk.position.x + nearest_chunk.position_diff_x,
			center[1] - nearest_chunk.position.z - nearest_chunk.position_diff_z)
		any_change_done = true
	
	if any_change_done:
		waiting_to_apply = true
		call_deferred("apply_new_data")


func apply_new_data():
	for chunk in $Chunks.get_children():
		if chunk.changed:
			chunk.apply_textures()
			
			chunk.position.x += chunk.position_diff_x
			chunk.position.z += chunk.position_diff_z
			
			chunk.position_diff_x = 0.0
			chunk.position_diff_z = 0.0
	
	logger.info("Applied new RealisticTerrainRenderer data for %s" % [name])
	waiting_to_apply = false


func _process(delta):
	super._process(delta)
	
	for decal in $Decals.get_children():
		decal.update(position_manager.center_node.position)


func get_debug_info() -> String:
	return "{0} chunks with a maximum size of {1} m.".format([
		chunks.size(),
		chunks.back().size
	])
