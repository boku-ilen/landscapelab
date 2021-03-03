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

var directions = {
	"up": false,
	"down": false,
	"right": false,
	"left": false
}

onready var action_handler = $ActionHandler


func _ready():
	$ActionHandler.player = self
	$ActionHandler.cursor = $Head/Camera/MousePoint/InteractRay
	$ActionHandler.collision_indicator = $Head/Camera/MousePoint/MouseCollisionIndicator


# Immediately stop all movement from directions dict
func stop_movement():
	for dir in directions:
		directions[dir] = false


func get_look_direction():
	# TODO: The x-coordinate seems right, but the z-coordinate acts strangely...
	return -$Head/Camera.global_transform.basis.z


func _physics_process(delta):
	fly(delta)


func _handle_general_input(event):
	if $ActionHandler.has_blocking_action():
		$ActionHandler.action(event)
	else:
		$ActionHandler.action(event)
		if event is InputEventMouseMotion and rotating:
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
	
	# Apply the movement
	move_and_slide(target)
	
	if walking:
		# FIXME: Place player on ground (using the terrain layer?)
		pass
