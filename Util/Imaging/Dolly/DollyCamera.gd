extends Camera

#
# Camera which goes along a PathFollow and keeps the view centered on a certain target (any Spatial node).
# Must be child of a PathFollow node!
#

var path_follow: PathFollow
var focus: Spatial
var velocity: Vector3

var is_enabled: bool = false

export(float) var move_speed: float
export(float, 0.0, 1.0) var move_speed_decay: float


func _ready():
	if not path_follow:
		logger.error("Dolly-cam needs a path_follow. Usually this gets set when the path-scene is instanced", "DOLLYCAM")
		assert(false, "Dolly-cam needs a path_follow. Usually this gets set when the path-scene is instanced")


func _process(delta):
	if is_enabled:
		# Keep the view towards the object
		if focus:
			look_at(focus.global_transform.origin, Vector3.UP) 
		
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
		#translation += Vector3(velocity.x, velocity.y, 0.0)
		rotation += Vector3(velocity.x, velocity.y, 0.0)


func toggle_cam(enabled):
	is_enabled = enabled
	visible = enabled
