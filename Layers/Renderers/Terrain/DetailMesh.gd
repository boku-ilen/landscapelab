extends MeshInstance3D

var size = 100

var previous_player_position := Vector3.ZERO
var min_load_distance := 1.0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Only do an update if the player has moved sufficiently since last frame
	if previous_player_position.distance_squared_to(get_parent().position_manager.center_node.position) < min_load_distance: return
	
	position.x = get_parent().position_manager.center_node.position.x
	position.z = get_parent().position_manager.center_node.position.z
	
	# FIXME: This actually depends on the terrain chunk resolution at the highest LOD.
	#  We use 2.0 here because at the highest LOD, one quad covers 2x2 meters.
	position.x -= fposmod(position.x, 2.0)
	position.z -= fposmod(position.z, 2.0)
	
	var origin_x = get_parent().center[0] - size / 2.0 + position.x
	var origin_z = get_parent().center[1] + size / 2.0 - position.z
	
	var heightmap = get_parent().layer_composition.render_info.height_layer.get_image(
		origin_x,
		origin_z,
		size,
		size / 2,
		0
	)
	
	var texture = get_parent().layer_composition.render_info.texture_layer.get_image(
		origin_x,
		origin_z,
		size,
		size,
		0
	)
	
	var landuse = get_parent().layer_composition.render_info.landuse_layer.get_image(
		origin_x,
		origin_z,
		size,
		size,
		0
	)
	
	material_override.set_shader_parameter("make_hole", false)
	material_override.set_shader_parameter("size", size)
	material_override.set_shader_parameter("heightmap", heightmap.get_image_texture())
	material_override.set_shader_parameter("orthophoto", texture.get_image_texture())
	material_override.set_shader_parameter("landuse", landuse.get_image_texture())
	material_override.set_shader_parameter("detail_noise", preload("res://Layers/Renderers/Terrain/Materials/DetailNoise.tres"))
	material_override.set_shader_parameter("detail_noise_lid_weights", [
		0.2, # Asphalt
		0.28, # Gravel
		0.45, # Lawn
		1.8, # Rock
		0.7, # Ice
		0.9, # Water
		0.5, # Grassland
		0.9, # Forest
		0.7, # Agroforest
		0.7, # Agriculture
		
	])
	
	previous_player_position = get_parent().position_manager.center_node.position
