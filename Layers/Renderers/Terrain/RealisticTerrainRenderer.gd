extends LayerRenderer


var lods = []

var chunk_size = 1000
var extent = 7 # extent of chunks in every direction

@export var basic_ortho_resolution := 100
@export var basic_landuse_resolution := 10
@export var basic_mesh := preload("res://Layers/Renderers/Terrain/lod_mesh_100x100.obj")
@export var basic_mesh_resolution := 100

@export var detailed_load_distance := 2000.0
@export var detailed_ortho_resolution := 2000
@export var detailed_mesh := preload("res://Layers/Renderers/Terrain/lod_mesh_300x300.obj")
@export var detailed_mesh_resolution := 300


func _ready():
	for x in range(-extent, extent + 1):
		for y in range(-extent, extent + 1):
			var lod = preload("res://Layers/Renderers/Terrain/TerrainLOD.tscn").instantiate()
			
			var size = chunk_size
			var lod_position = Vector3(x * size, 0.0, y * size)
			
			lod.position = lod_position
			lod.size = size
			
			lod.ortho_resolution = basic_ortho_resolution
			lod.landuse_resolution = basic_landuse_resolution
			lod.mesh = basic_mesh
			lod.mesh_resolution = basic_mesh_resolution
			
			lod.height_layer = layer.render_info.height_layer.clone()
			lod.texture_layer = layer.render_info.texture_layer.clone()
			lod.landuse_layer = layer.render_info.landuse_layer.clone()
			lod.surface_height_layer = layer.render_info.surface_height_layer.clone()
			
			lods.append(lod)
	
	for lod in lods:
		add_child(lod)


func is_new_loading_required(position_diff: Vector3) -> bool:
	if abs(position_diff.x) > chunk_size or abs(position_diff.z) > chunk_size:
		return true
	else:
		return false


func full_load():
	for lod in lods:
		var remainder_x = center[0] % chunk_size
		var remainder_y = center[1] % chunk_size
		
		lod.position_diff_x = remainder_x
		lod.position_diff_z = remainder_y
		
		lod.build(center[0] + lod.position.x + lod.position_diff_x, center[1] - lod.position.z - lod.position_diff_z)
	
	call_deferred("apply_new_data")


func adapt_load(position_diff: Vector3):
	for lod in lods:
		lod.position_diff_x = 0.0
		lod.position_diff_z = 0.0

		var changed = false

		if lod.position.x - position_manager.center_node.position.x >= chunk_size * extent:
			lod.position_diff_x = -chunk_size * extent * 2 - chunk_size
			changed = true
		if lod.position.x - position_manager.center_node.position.x <= -chunk_size * extent:
			lod.position_diff_x = chunk_size * extent * 2 + chunk_size
			changed = true
		if lod.position.z - position_manager.center_node.position.z >= chunk_size * extent:
			lod.position_diff_z = -chunk_size * extent * 2 - chunk_size
			changed = true
		if lod.position.z - position_manager.center_node.position.z <= -chunk_size * extent:
			lod.position_diff_z = chunk_size * extent * 2 + chunk_size
			changed = true
		
		if changed:
			lod.build(center[0] + lod.position.x + lod.position_diff_x, center[1] - lod.position.z - lod.position_diff_z)
	
	call_deferred("apply_new_data")


func get_nearest_lod_below_resolution(query_position: Vector3, resolution: int, max_distance: float):
	var nearest_distance = INF
	var nearest_lod
	
	for lod in lods:
		if lod.ortho_resolution < resolution:
			var distance = lod.position.distance_to(query_position)
			if distance < nearest_distance and distance < max_distance:
				nearest_distance = distance
				nearest_lod = lod
	
	return nearest_lod


func refine_load():
	# Downgrade LODs which are now too far away
	for lod in lods:
		if lod.ortho_resolution >= detailed_ortho_resolution and \
				lod.position.distance_to(position_manager.center_node.position) > detailed_load_distance:
			lod.position_diff_x = 0
			lod.position_diff_z = 0
		
			lod.mesh = basic_mesh
			lod.mesh_resolution = basic_mesh_resolution
			lod.ortho_resolution = basic_ortho_resolution
			lod.build(center[0] + lod.position.x + lod.position_diff_x,
				center[1] - lod.position.z - lod.position_diff_z)
			lod.changed = true
	
	# Upgrade nearby LODs
	var nearest_lod = get_nearest_lod_below_resolution(position_manager.center_node.position, detailed_ortho_resolution, detailed_load_distance)
	
	if nearest_lod:
		nearest_lod.position_diff_x = 0
		nearest_lod.position_diff_z = 0
		
		nearest_lod.mesh = detailed_mesh
		nearest_lod.mesh_resolution = detailed_mesh_resolution
		nearest_lod.ortho_resolution = detailed_ortho_resolution
		
		nearest_lod.build(center[0] + nearest_lod.position.x + nearest_lod.position_diff_x,
			center[1] - nearest_lod.position.z - nearest_lod.position_diff_z)
		nearest_lod.changed = true
	
	call_deferred("apply_new_data")


func apply_new_data():
	for lod in get_children():
		if lod.changed:
			lod.position.x += lod.position_diff_x
			lod.position.z += lod.position_diff_z
			
			lod.apply_textures()


func get_debug_info() -> String:
	return "{0} LODs with a maximum size of {1} m.".format([
		lods.size(),
		lods.back().size
	])
