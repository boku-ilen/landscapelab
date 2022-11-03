extends LayerCompositionRenderer


var lods = []
var previous_center

var chunk_size = 1000
var extent = 7 # extent of chunks in every direction

var update_thread = Thread.new()


func _ready():
	for x in range(-extent, extent + 1):
		for y in range(-extent, extent + 1):
			var lod = preload("res://Layers/Renderers/Terrain/TerrainLOD.tscn").instantiate()

			var size = chunk_size
			var lod_position = Vector3(x * size, 0.0, y * size)

			lod.position = lod_position
			lod.size = size

#			if x == 0 and y == 0:
#				lod.ortho_resolution = 1000
#				lod.landuse_resolution = 100
#			else:
			lod.ortho_resolution = 100
			lod.landuse_resolution = 10
			
			lod.height_layer = layer_composition.render_info.height_layer.clone()
			lod.texture_layer = layer_composition.render_info.texture_layer.clone()
			lod.landuse_layer = layer_composition.render_info.landuse_layer.clone()
			lod.surface_height_layer = layer_composition.render_info.surface_height_layer.clone()

			lods.append(lod)
	
#	# Spawn LODs
#	for scales in range(4):
#		for x in range(-1, 2):
#			for y in range(-1, 2):
#				var lod = preload("res://Layers/Renderers/Terrain/TerrainLOD.tscn").instantiate()
#
#				if x == 0 and y == 0:
#					if scales == 0:
#						lod.mesh = preload("res://Layers/Renderers/Terrain/lod_mesh_300x300.obj")
#						lod.mesh_resolution = 300
#					else:
#						continue
#
##				if scales == 0:
##					lod.load_detail_textures = true
##					lod.load_fade_textures = true
##				elif scales == 1:
##					lod.load_fade_textures = true
##				else:
##					lod.always_load_landuse = true
#
#				var size = pow(3.0, scales) * 300.0
#				lod.position.x = x * size
#				lod.position.z = y * size
#				lod.size = size
#
#				lod.height_layer = layer.render_info.height_layer.clone()
#				lod.texture_layer = layer.render_info.texture_layer.clone()
#				lod.landuse_layer = layer.render_info.landuse_layer.clone()
#				lod.surface_height_layer = layer.render_info.surface_height_layer.clone()
#
#				lods.append(lod)
	
	for lod in lods:
		add_child(lod)


func load_new_data():
	if previous_center == null:
		previous_center = [0, 0]
		
		for lod in lods:
			var remainder_x = center[0] % chunk_size
			var remainder_y = center[1] % chunk_size
			
			lod.position_diff_x = remainder_x
			lod.position_diff_z = remainder_y
			
			lod.build(center[0] + lod.position.x + lod.position_diff_x, center[1] - lod.position.z - lod.position_diff_z)
	else:
		var nearest_lod_distance = INF
		var nearest_lod
		
		for lod in lods:
			lod.position_diff_x = previous_center[0] - center[0]
			lod.position_diff_z = center[1] - previous_center[1]
			
#			var remainder_x = center[0] % chunk_size
#			var remainder_y = center[1] % chunk_size
#
#			lod.position_x = center[0]
#			lod.position_y = center[1]

			var changed = false

			while lod.position.x + lod.position_diff_x >= chunk_size * extent:
				lod.position_diff_x += -chunk_size * extent * 2 - chunk_size
				changed = true
			while lod.position.x + lod.position_diff_x <= -chunk_size * extent:
				lod.position_diff_x += chunk_size * extent * 2 + chunk_size
				changed = true
			while lod.position.z + lod.position_diff_z >= chunk_size * extent:
				lod.position_diff_z += -chunk_size * extent * 2 - chunk_size
				changed = true
			while lod.position.z + lod.position_diff_z <= -chunk_size * extent:
				lod.position_diff_z += chunk_size * extent * 2 + chunk_size
				changed = true
			
			if changed:
				lod.build(center[0] + lod.position.x + lod.position_diff_x, center[1] - lod.position.z - lod.position_diff_z)
			
			var distance = lod.position.length_squared()
			
			if distance < nearest_lod_distance:
				nearest_lod_distance = distance
				nearest_lod = lod
	
		nearest_lod.ortho_resolution = 1000
		nearest_lod.landuse_resolution = 100
		nearest_lod.build(center[0] + nearest_lod.position.x + previous_center[0] - center[0], center[1] - nearest_lod.position.z - center[1] + previous_center[1])
		nearest_lod.changed = true
	
	previous_center[0] = center[0]
	previous_center[1] = center[1]


func apply_new_data():
	for lod in get_children():
		lod.position.x += lod.position_diff_x
		lod.position.z += lod.position_diff_z
		
		if lod.changed:
			lod.apply_textures()


func get_debug_info() -> String:
	return "{0} LODs with a maximum size of {1} m.".format([
		lods.size(),
		lods.back().size
	])
