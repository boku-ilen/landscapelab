extends KinematicBody

var origin_offset_x : int = 0
var origin_offset_z : int = 0

var mouse_sensitivity = 0.1
var camera_angle = 0
var velocity = Vector3()

var walking = false

var WALK_SPEED = Settings.get_setting("player", "ground-speed")
var FLY_SPEED = Settings.get_setting("player", "fly-speed")
var SPRINT_SPEED = Settings.get_setting("player", "fly-speed-sprint")
var SNEAK_SPEED = Settings.get_setting("player", "fly-speed-sneak")

onready var head = get_node("Head")
onready var camera = head.get_node("Camera")

# To prevent floating point errors, the player.translation does not reflect the player's actual position in the whole world.
# This function returns the true world position of the player in int.
func get_true_position():
	return Offset.to_world_coordinates(translation)

# Shift the player's in-engine translation by a certain offset, but not the player's true coordinates.
func shift(delta_x, delta_z):
	PlayerInfo.add_player_pos(Vector3(delta_x, 0, delta_z))
	
	translation.x += delta_x
	translation.z += delta_z
	
func _enter_tree():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _exit_tree():
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)

func _ready():
	Offset.connect("shift_world", self, "shift")

func _physics_process(delta):
	fly(delta)
	
	# Reflect new position in global PlayerInfo
	PlayerInfo.update_player_pos(translation)

func _input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(deg2rad(-event.relative.x * mouse_sensitivity))
		
		var change = -event.relative.y * mouse_sensitivity
		
		if change + camera_angle < 90 and change + camera_angle > -90:
			camera.rotate_x(deg2rad(change))
			camera_angle += change
			
	elif event.is_action_pressed("pc_toggle_walk"):
		walking = not walking

func fly(delta):
	# reset the direction of the player
	var direction = Vector3()
	
	# get the rotation of the camera
	var aim = camera.get_global_transform().basis
	
	# check input and change direction
	if Input.is_action_pressed("ui_up"):
		direction -= aim.z
	if Input.is_action_pressed("ui_down"):
		direction += aim.z
	if Input.is_action_pressed("ui_left"):
		direction -= aim.x
	if Input.is_action_pressed("ui_right"):
		direction += aim.x
	
	direction = direction.normalized()
	
	if Input.is_action_pressed("ui_sprint"):
		direction *= SPRINT_SPEED / FLY_SPEED
	elif Input.is_action_pressed("ui_sneak"):
		direction *= SNEAK_SPEED / FLY_SPEED
	
	# where would the player go at max speed
	var target
	
	if walking:
		target = direction * WALK_SPEED
	else:
		target = direction * FLY_SPEED
	
	# move
	move_and_slide(target)
	
	if walking:
		translation = WorldPosition.get_position_on_ground(translation)
