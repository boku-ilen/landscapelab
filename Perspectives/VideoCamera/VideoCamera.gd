extends Camera


# TODO: Remove this node and the reference to it, set this from outside
onready var view_target: MeshInstance = get_node("Node/MeshInstance")

# movement speed
var translate_forward: float = 0.0
var translate_backward: float = 0.0
var translate_right: float = 0.0
var translate_left: float = 0.0
var translate_up: float = 0.0
var translate_down: float = 0.0

export var move_speed: float
export var move_speed_decay: float


func _process(delta):
	# Keep the view towards the object
	look_at(view_target.global_transform.origin, Vector3.UP)
	
	if Input.is_action_pressed("camera_move_forward"):
		translate_forward += move_speed * delta
	if Input.is_action_pressed("camera_move_backward"):
		translate_backward += move_speed * delta
	if Input.is_action_pressed("camera_move_right"):
		translate_right += move_speed * delta
	if Input.is_action_pressed("camera_move_left"):
		translate_left += move_speed * delta
	if Input.is_action_pressed("camera_move_up"):
		translate_up += move_speed * delta
	if Input.is_action_pressed("camera_move_down"):
		translate_down += move_speed * delta
	
	translate_backward *= move_speed_decay
	translate_forward *= move_speed_decay
	translate_right *= move_speed_decay
	translate_left *= move_speed_decay
	translate_up *= move_speed_decay
	translate_down *= move_speed_decay
	
	global_translate(Vector3.FORWARD * translate_forward)
	global_translate(Vector3.BACK * translate_backward)
	global_translate(Vector3.RIGHT * translate_right)
	global_translate(Vector3.LEFT * translate_left)
	global_translate(Vector3.UP * translate_up)
	global_translate(Vector3.DOWN * translate_down)
