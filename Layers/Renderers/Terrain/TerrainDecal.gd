extends Decal


@export var render_normals := false
@export var render_distance := 20.0
@export var resolution := 10.0

var previous_update_position = Vector3.ZERO


func _ready():
	size.x = render_distance
	size.z = render_distance
	
	upper_fade = 0.0
	lower_fade = 0.0
	
	sorting_offset = -render_distance
	
	$DecalViewport/Camera3D.size = render_distance
	$DecalViewport.size = Vector2i(resolution, resolution)
	
	if render_normals:
		$DecalViewportNormal.debug_draw = Viewport.DEBUG_DRAW_NORMAL_BUFFER
		$DecalViewportNormal/Camera3D.size = render_distance
		$DecalViewportNormal.size = Vector2i(resolution, resolution)
		
		texture_normal = $DecalViewportNormal.get_texture()


func update(player_position):
	# Don't update if there hasn't been a sufficient change in position
	if player_position.distance_to(previous_update_position) < render_distance / 20.0:
		return
	
	previous_update_position = player_position
	
	var new_pos = Vector3i(player_position) \
		+ Vector3i.UP * int(render_distance)
	
	$DecalViewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	$DecalViewport/Camera3D.position = new_pos
	
	if render_normals:
		$DecalViewportNormal.render_target_update_mode = SubViewport.UPDATE_ONCE
		$DecalViewportNormal/Camera3D.position = new_pos
	
	await get_tree().process_frame
	
	position = new_pos
	
	# Workaround, see https://github.com/godotengine/godot/issues/73400
	var texture_albedo_buffer = texture_albedo
	texture_albedo = null
	texture_albedo = texture_albedo_buffer
