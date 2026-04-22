extends Node3D

@export var automated_camera: Camera3D
@export var vr_camera: XRCamera3D

@export var smoothness = 2.0
@export var smoothness_snappy := 0.5

@export var min_fov := 25.0
@export var max_fov := 50.0
@export var rotating_fov := 45.0

var current_target_basis
var current_target_location
var current_target_fov

@export var rotation_start_threshold := PI / 2.0
@export var rotation_stop_threshold := PI / 8.0

var is_vr_active := false

@export var active := true

var target_overridden = false

# Called when the node enters the scene tree for the first time.
func _ready():
	GameSystem.game_mode_changed.connect(on_game_mode_changed)
	
	var xr_interface = XRServer.find_interface("OpenXR")
	
	xr_interface.session_visible.connect(func(): is_vr_active = false)
	xr_interface.session_focussed.connect(func(): is_vr_active = true)


func on_game_mode_changed():
	for goc in GameSystem.current_game_mode.game_object_collections.values():
		goc.game_object_changed.connect(on_game_object_changed)


func on_game_object_changed(game_object):
	var go_position = game_object.get_position() * Vector3(1.0, 1.0, -1.0)
	current_target_location = get_parent().position_manager.to_engine_coordinates(go_position)
	target_overridden = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("set_autolook_active"): active = not active
	
	if not active: return
	
	if is_vr_active:
		current_target_location = global_position + vr_camera.global_transform.basis.z 
	
	if current_target_location:
		var look_at_vector = current_target_location - global_position * Vector3(1.0, 0.0, 1.0)
		current_target_basis = Basis.looking_at(look_at_vector)
		
		current_target_fov = lerp(max_fov, min_fov, clamp(look_at_vector.length() / 10000, 0.0, 1.0))
	
	if get_parent().rotating:
		target_overridden = true
		#automated_camera.fov = lerp(automated_camera.fov, rotating_fov, (1.0 / smoothness_snappy) * delta)
	
	if not target_overridden:
		#if current_target_fov:
			#automated_camera.fov = lerp(automated_camera.fov, current_target_fov, (1.0 / smoothness) * delta)
		
		if current_target_basis:
			var lerp_factor = (1.0 / smoothness) * delta
			
			automated_camera.get_parent().rotation.y = lerp(
				automated_camera.get_parent().rotation.y,
				current_target_basis.get_euler().y,
				lerp_factor
			)
			automated_camera.rotation.x = lerp(
				automated_camera.rotation.x,
				current_target_basis.get_euler().x,
				lerp_factor
			)
