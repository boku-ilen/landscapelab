extends AbstractPlayer

#
# Player Controller with classic first person movement as well as dragging and zooming.
#

var velocity = Vector3()
var _vr_mode : bool = false

var walking = Settings.get_setting("player", "start-walking-enabled")

var FLY_SPEED = Settings.get_setting("player", "fly-speed")
var WALK_SPEED = Settings.get_setting("player", "walk-speed-default")
var SPRINT_SPEED = Settings.get_setting("player", "fly-speed-sprint")
var SNEAK_SPEED = Settings.get_setting("player", "fly-speed-sneak")
var MAX_DISTANCE_TO_GROUND = Settings.get_setting("third-person", "max-distance-to-ground")
var START_DISTANCE_TO_GROUND = Settings.get_setting("third-person", "start_height")
var MOUSE_ZOOM_SPEED = Settings.get_setting("third-person", "mouse-zoom-speed")

var MOUSE_ACCELERATION = Settings.get_setting("player", "smooth-mouse-acceleration")
var MOUSE_DRAG = Settings.get_setting("player", "smooth-mouse-drag")

var directions = {
	"up": false,
	"down": false,
	"right": false,
	"left": false
}

var is_smooth_camera := false
var current_mouse_velocity := Vector2.ZERO

onready var action_handler = $ActionHandler
onready var camera = $Head/Camera


func _ready():
	$ActionHandler.player = self
	$ActionHandler.cursor = $Head/Camera/MousePoint/InteractRay
	$ActionHandler.collision_indicator = $Head/Camera/MousePoint/MouseCollisionIndicator


# Immediately stop all movement from directions dict
func stop_movement():
	for dir in directions:
		directions[dir] = false


func get_look_direction():
	return Vector3.UP.cross($Head/Camera.global_transform.basis.x)


func _physics_process(delta):
	fly(delta)
	
	if is_smooth_camera:
		$Head.rotate_y(current_mouse_velocity.y)
		
		# Limit the view to between straight down and straight up
		if current_mouse_velocity.x + $Head/Camera.rotation_degrees.x < 90 \
				and current_mouse_velocity.x + $Head/Camera.rotation_degrees.x > -90:
			$Head/Camera.rotate_x(current_mouse_velocity.x)
		
		current_mouse_velocity *= MOUSE_DRAG


func _handle_general_input(event):
	if $ActionHandler.has_blocking_action():
		$ActionHandler.action(event)
	else:
		$ActionHandler.action(event)
		if event is InputEventMouseMotion and rotating:
			if is_smooth_camera:
				current_mouse_velocity.y += -event.relative.x * MOUSE_ACCELERATION
				current_mouse_velocity.x += -event.relative.y * MOUSE_ACCELERATION
			else:
				$Head.rotate_y(deg2rad(-event.relative.x * mouse_sensitivity))
				
				var change = -event.relative.y * mouse_sensitivity
				
				# Limit the view to between straight down and straight up
				if change + $Head/Camera.rotation_degrees.x < 90 \
						and change + $Head/Camera.rotation_degrees.x > -90:
					$Head/Camera.rotate_x(deg2rad(change))
			
			get_tree().set_input_as_handled()
			
		if event.is_action_pressed("pc_move_up"):
			directions.up = true
		elif event.is_action_released("pc_move_up"):
			directions.up = false
		if event.is_action_pressed("pc_move_down"):
			directions.down = true
		elif event.is_action_released("pc_move_down"):
			directions.down = false
		if event.is_action_pressed("pc_move_left"):
			directions.left = true
		elif event.is_action_released("pc_move_left"):
			directions.left = false
		if event.is_action_pressed("pc_move_right"):
			directions.right = true
		elif event.is_action_released("pc_move_right"):
			directions.right = false



func _handle_viewport_input(event):
	# Zoom out/in
	if event.is_action_pressed("zoom_out"): # Move down when scrolling up
		get_tree().set_input_as_handled()
		move_and_collide(Vector3.UP * -MOUSE_ZOOM_SPEED)
		
		# TODO: Instead of 0, use the ground height at this position
		translation.y = clamp(translation.y, 0, MAX_DISTANCE_TO_GROUND)
	elif event.is_action_pressed("zoom_in"): # Move up when scrolling down
		get_tree().set_input_as_handled()
		move_and_collide(Vector3.UP * MOUSE_ZOOM_SPEED)
		
		# TODO: Instead of 0, use the ground height at this position
		translation.y = clamp(translation.y, 0, MAX_DISTANCE_TO_GROUND)
	
	# Dragging
	elif event is InputEventMouseMotion and dragging:
		var mouseMovement = Vector3(event.relative.x, 0, event.relative.y)
		
		# Rotate the movement along the Head to make it relative to the view direction
		mouseMovement = mouseMovement.rotated(Vector3.UP, $Head.rotation.y)
		
		move_and_collide(-mouseMovement * translation.y / 1000)  # FIXME: hardcoded value
		
		return true
	
	# Switches
	if event.is_action_pressed("pc_toggle_walk"):
		walking = not walking
		
		get_tree().set_input_as_handled()
		return true
	
	# Misc
	elif event.is_action_pressed("make_asset_only_screenshot"):
		# TODO: This doesn't really belong here and should be generalized.
		# Here we make a high-res screenshot with only the assets, the rest is
		#  transparent, for overlaying on top of real photos.
		
		# First, make a raw photo
		# Retrieve the captured image
		var img = get_viewport().get_texture().get_data()
		
		# Flip it on the y-axis (because it's flipped)
		img.flip_y()
		
		img.save_png("user://photo-raw-%d" % [OS.get_system_time_msecs()])
		
		
		var previous_viewport_size = get_viewport().size
		
		$Head/Camera.cull_mask = 16
		get_viewport().transparent_bg = true
		get_viewport().size = Vector2(3888, 2592)
		
		VisualServer.force_draw()
		
		# Retrieve the captured image
		img = get_viewport().get_texture().get_data()
		
		# Flip it on the y-axis (because it's flipped)
		img.flip_y()
		
		img.save_png("user://photo-%d" % [OS.get_system_time_msecs()])
		
		$Head/Camera.cull_mask = 23+32+64
		get_viewport().transparent_bg = false
		get_viewport().size = previous_viewport_size
		
		VisualServer.force_draw()


func fly(delta):
	# Reset the direction of the player
	var direction = Vector3()
	
	# Get the rotation of the camera
	var aim = $Head/Camera.get_global_transform().basis
	
	# Check input and change direction
	if directions.up:
		direction -= aim.z
	if directions.down:
		direction += aim.z
	if directions.left:
		direction -= aim.x
	if directions.right:
		direction += aim.x
	
	direction = direction.normalized()
	
	if Input.is_action_pressed("ui_sprint"):
		direction *= SPRINT_SPEED
	elif Input.is_action_pressed("ui_sneak"):
		direction *= SNEAK_SPEED
	
	var target = direction * WALK_SPEED if walking else direction * FLY_SPEED
	
	# If the player would move outside of the boundary, keep them inside
	var future_world_coordinates = position_manager.to_world_coordinates(translation + target * delta)
	var boundary = position_manager.get_rendered_boundary()
	
	if future_world_coordinates[0] < boundary[0]: target.x += (boundary[0] - future_world_coordinates[0]) / delta
	if future_world_coordinates[0] > boundary[1]: target.x -= (future_world_coordinates[0] - boundary[1]) / delta
	if future_world_coordinates[2] < boundary[2]: target.z -= (boundary[2] - future_world_coordinates[2]) / delta
	if future_world_coordinates[2] > boundary[3]: target.z += (future_world_coordinates[2] - boundary[3]) / delta
	
	move_and_slide(target)
	
	if walking:
		var space_state = get_world().direct_space_state
		var result = space_state.intersect_ray(
			Vector3(translation.x, 6000, translation.z),
			Vector3(translation.x, -1000, translation.z), [self])

		if result:
			transform.origin.y = result.position.y


func get_world_position():
	return position_manager.to_world_coordinates(translation)


func set_world_position(world_position):
	var new_pos = position_manager.to_engine_coordinates(world_position)
	translation.x = new_pos.x
	translation.z = new_pos.z
	# FIXME: Should probably get the ground height and use it for the y position
