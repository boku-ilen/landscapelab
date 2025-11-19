extends MeshInstance3D

@export var size := 100

@export var height_resolution := 100
@export var lu_resolution := 100

@export var add_lid_overlay := true
@export var add_height_overlay := false
@export var is_inner := true

# Only relevant if is_inner is false
@export var hole_size := 8000.0

var previous_player_position := Vector3.ZERO

@export var min_load_distance := 1.0


func _ready():
	if add_lid_overlay:
		var vp = preload("res://Layers/Renderers/Overlay/LIDOverlayViewport.tscn").instantiate()
		vp.set_resolution(size * 4.0)  # 0.25m resolution
		vp.set_size(size)
		add_child(vp)
	
	if add_height_overlay:
		var vp = preload("res://Layers/Renderers/Overlay/HeightOverlayViewport.tscn").instantiate()
		vp.set_resolution(size * 4.0)  # 0.25m resolution
		vp.set_size(size)
		add_child(vp)
	
	# Avoid resolution higher than data resolution
	var height_pixel_size = get_parent().layer_composition.render_info.height_layer.get_pixel_size()
	height_resolution = min(height_resolution, size / height_pixel_size)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if has_node("HeightOverlayViewport"): get_node("HeightOverlayViewport").set_resolution(size * 4.0)
	# Only do an update if the player has moved sufficiently since last frame
	if previous_player_position.distance_squared_to(get_parent().position_manager.center_node.position) < min_load_distance: return
	
	#var time = Time.get_ticks_msec()
	
	position.x = get_parent().position_manager.center_node.position.x
	position.z = get_parent().position_manager.center_node.position.z
	
	# Snap to the resolution to avoid constant "jumps" in the height
	position = position.snappedf(size / height_resolution)
	
	var origin_x = get_parent().center[0] - size / 2.0 + position.x - 1
	var origin_z = get_parent().center[1] + size / 2.0 - position.z + 1
	
	var heightmap = get_parent().layer_composition.render_info.height_layer.get_image(
		origin_x,
		origin_z,
		size + 1,
		height_resolution + 1,
		0
	)
	
	var landuse = get_parent().layer_composition.render_info.landuse_layer.get_image(
		origin_x,
		origin_z,
		size,
		lu_resolution,
		0
	)
	
	material_override.set_shader_parameter("use_landuse_overlay", add_lid_overlay)
	material_override.set_shader_parameter("make_hole", not is_inner)
	material_override.set_shader_parameter("size", size)
	material_override.set_shader_parameter("hole_size", hole_size)
	
	material_override.set_shader_parameter("heightmap", heightmap.get_image_texture())
	material_override.set_shader_parameter("landuse", landuse.get_image_texture())
	
	if add_lid_overlay:
		material_override.set_shader_parameter("landuse_overlay", get_node("LIDOverlayViewport").get_texture())
	
	if add_height_overlay:
		material_override.set_shader_parameter("use_height_overlay", true)
		material_override.set_shader_parameter("height_overlay", get_node("HeightOverlayViewport").get_texture())
	
	# Next pass (water etc)
	var next_pass = material_override.next_pass
	
	if next_pass:
		var surface_heightmap = get_parent().layer_composition.render_info.surface_height_layer.get_image(
			origin_x,
			origin_z,
			size,
			height_resolution,
			0
		)
		
		while next_pass:
			next_pass.set_shader_parameter("heightmap", heightmap.get_image_texture())
			next_pass.set_shader_parameter("surface_heightmap", surface_heightmap.get_image_texture())
			next_pass.set_shader_parameter("landuse", landuse.get_image_texture())
			next_pass.set_shader_parameter("hole_size", hole_size)
			next_pass.set_shader_parameter("make_hole", true)
			if add_lid_overlay:
				next_pass.set_shader_parameter("landuse_overlay", get_node("LIDOverlayViewport/LIDViewport").get_texture())
				next_pass.set_shader_parameter("use_landuse_overlay", true)
			else:
				next_pass.set_shader_parameter("use_landuse_overlay", false)
			
			if add_height_overlay:
				next_pass.set_shader_parameter("use_height_overlay", true)
				next_pass.set_shader_parameter("height_overlay", get_node("HeightOverlayViewport").get_texture())
			else:
				next_pass.set_shader_parameter("use_height_overlay", false)
			
			next_pass.set_shader_parameter("size", size)
		
			next_pass = next_pass.next_pass
	
	previous_player_position = get_parent().position_manager.center_node.position
	
	#if not add_lid_overlay:
		#print("Took %s ms" % [str(Time.get_ticks_msec() - time)])
