extends Camera

#
# Camera which goes along a PathFollow and keeps the view centered on a certain target (any Spatial node).
# Must be child of a PathFollow node!
#


export(NodePath) var path_follow_nodepath


# TODO: Remove this ugly path hacking
onready var view_target: Spatial = get_node("../../../../../Focus")
onready var path_follow: PathFollow

# movement speed
var velocity: Vector3

export(float) var move_speed: float
export(float, 0.0, 1.0) var move_speed_decay: float


func _ready():
	path_follow = get_node(path_follow_nodepath) as PathFollow
	
	if not path_follow:
		logger.error("Parent node of VideoCamera must be a PathFollow which the camera can go along!")
	
	# FIXME: Ugly... but 0 doesn't move it to the beginning of the path
	path_follow.offset = 0.0001


func _process(delta):
	# Keep the view towards the object
	look_at(view_target.global_transform.origin, Vector3.UP)
	
	if Input.is_action_pressed("camera_move_forward"):
		velocity.z += move_speed * delta
	if Input.is_action_pressed("camera_move_backward"):
		velocity.z -= move_speed * delta
	if Input.is_action_pressed("camera_move_right"):
		velocity.x += move_speed * delta
	if Input.is_action_pressed("camera_move_left"):
		velocity.x -= move_speed * delta
	if Input.is_action_pressed("camera_move_up"):
		velocity.y += move_speed * delta
	if Input.is_action_pressed("camera_move_down"):
		velocity.y -= move_speed * delta
	
	# Make x and y velocity decay over time, z (forward/backward) velocity stays the same
	velocity.x *= move_speed_decay
	velocity.y *= move_speed_decay
	
	# Movement along rails
	path_follow.offset += velocity.z
	
	# Free movement relative to position on rails
	translation += Vector3(velocity.x, velocity.y, 0.0)
