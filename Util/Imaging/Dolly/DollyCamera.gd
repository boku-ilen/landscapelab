extends Camera3D

#
# Camera3D which goes along a PathFollow3D and keeps the view centered checked a certain target (any Node3D node).
# Must be top level (i.e. position must return the "global" position). Can be achieved by e.g. pushing the
# transform of the pathfollow using a a remotetransform
#

@export var path_follow: PathFollow3D
@export var path_follow_focus: PathFollow3D
@export var focus: Node3D
@export var move_speed: float
@export var pivot_speed: float
@export var pivot_speed_decay: float # (float, 0.0, 1.0)

var focus_enabled := false
var velocity: Vector3
var is_enabled := false


func _process(delta):
	if is_enabled:
		if Input.is_action_pressed("camera_move_forward"):
			velocity.z += move_speed * delta
		if Input.is_action_pressed("camera_move_backward"):
			velocity.z -= move_speed * delta
		if Input.is_action_pressed("camera_move_right"):
			velocity.x += pivot_speed * delta
		if Input.is_action_pressed("camera_move_left"):
			velocity.x -= pivot_speed * delta
		if Input.is_action_pressed("camera_move_up"):
			velocity.y += pivot_speed * delta
		if Input.is_action_pressed("camera_move_down"):
			velocity.y -= pivot_speed * delta
		if Input.is_action_pressed("camera_stop"):
			velocity = Vector3.ZERO
		
		# Make x and y velocity decay over time, z (forward/backward) velocity stays the same
		velocity.x *= pivot_speed_decay
		velocity.y *= pivot_speed_decay
		
		# Movement along rails
		path_follow.progress += velocity.z * delta
		path_follow_focus.progress_ratio = path_follow.progress_ratio
		
		# Free movement relative to position checked rails
		position += Vector3(velocity.x, velocity.y, 0.0) * delta
		rotation += Vector3(velocity.x, velocity.y, 0.0) * delta
		
		# Keep the view towards the object
		if focus != null and focus_enabled:
			focus.visible = true
			look_at(focus.global_transform.origin, Vector3.UP) 


func get_look_direction():
	return -global_transform.basis.z


func toggle_cam(enabled):
	is_enabled = enabled
	visible = enabled
