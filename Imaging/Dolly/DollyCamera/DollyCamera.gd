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

var _using_dolly: bool = false

export(bool) var _using_shakiness: bool
export (float) var _shakiness: float
export (float) var _shakiness_pitch: float
export(float) var move_speed: float
export(float, 0.0, 1.0) var move_speed_decay: float


func _ready():
	UISignal.connect("toggle_imaging_view", self, "_toggle_imaging_view")
	
	path_follow = get_node(path_follow_nodepath) as PathFollow
	
	if not path_follow:
		logger.error("Parent node of VideoCamera must be a PathFollow which the camera can go along!")


func _process(delta):
	# Keep the view towards the object
	if _using_shakiness:
		var rand = rand_range(-_shakiness_pitch, _shakiness_pitch)
		var pitch_shakiness_offset = Vector3(0, rand, 0)
		look_at(view_target.global_transform.origin + pitch_shakiness_offset, Vector3.UP) 
	else:
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
	
	if _using_shakiness:
		rotation_degrees.z += rand_range(-_shakiness, _shakiness) * delta
		#rotation_degrees.x += rand_range(-_shakiness_pitch, _shakiness_pitch) * delta
	
	# Make x and y velocity decay over time, z (forward/backward) velocity stays the same
	velocity.x *= move_speed_decay
	velocity.y *= move_speed_decay
	
	# Movement along rails
	path_follow.offset += velocity.z
	
	# Free movement relative to position on rails
	translation += Vector3(velocity.x, velocity.y, 0.0)
	
	if _using_dolly:
		PlayerInfo.update_player_pos(translation)


func _toggle_imaging_view():
	_using_dolly = !_using_dolly
