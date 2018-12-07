extends KinematicBody

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

var mouse_sensitivity = 0.1
var camera_angle = 0
var velocity = Vector3()

var FLY_SPEED = 5000

onready var head = get_node("Head")
onready var camera = head.get_node("Camera")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	fly(delta)

func _input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(deg2rad(-event.relative.x * mouse_sensitivity))
		
		var change = -event.relative.y * mouse_sensitivity
		
		if change + camera_angle < 90 and change + camera_angle > -90:
			camera.rotate_x(deg2rad(change))
			camera_angle += change
			
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
		direction /= 10
	
	# where would the player go at max speed
	var target = direction * FLY_SPEED
	
	# move
	translation += target * delta