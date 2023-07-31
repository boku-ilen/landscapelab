extends Camera3D

#
# Camera3D which goes along a PathFollow3D and keeps the view centered checked a certain target (any Node3D node).
# Must be child of a PathFollow3D node!
#

var path_follow: PathFollow3D
var focus: Node3D
var velocity: Vector3

var is_enabled: bool = false

@export var move_speed: float
@export var move_speed_decay: float # (float, 0.0, 1.0)


func _ready():
	if not path_follow:
		logger.error("Dolly-cam needs a path_follow. Usually this gets set when the path-scene is instanced")
		assert(false) #,"Dolly-cam needs a path_follow. Usually this gets set when the path-scene is instanced")


func _process(delta):
	if is_enabled:
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
		path_follow.progress += velocity.z * delta
		
		# Free movement relative to position checked rails
		position += Vector3(velocity.x, velocity.y, 0.0) * delta
		rotation += Vector3(velocity.x, velocity.y, 0.0) * delta
		
		# Keep the view towards the object
		if focus:
			look_at(focus.global_transform.origin, Vector3.UP) 


func toggle_cam(enabled):
	is_enabled = enabled
	visible = enabled
