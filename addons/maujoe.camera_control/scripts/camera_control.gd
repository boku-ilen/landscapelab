# Licensed under the MIT License.
# Copyright (c) 2018 Jaccomo Lorenz (Maujoe)

extends Camera

# User settings:
# General settings
export var enabled = true setget set_enabled
export(int, "Visible", "Hidden", "Caputered, Confined") var mouse_mode = 2

# Mouslook settings
export var mouselook = true
export var controllerlook = true
export var lock_verical_look = false
export (float, 0.0, 1.0) var sensitivity = 0.5
export (float, 0.0, 0.999, 0.001) var smoothness = 0.5 setget set_smoothness
export(NodePath) var privot setget set_privot
export var distance = 5.0 setget set_distance
export var rotate_privot = false
export var collisions = true setget set_collisions
export (int, 0, 360) var yaw_limit = 360
export (int, 0, 360) var pitch_limit = 360

# Movement settings
export var movement = true
export (float, 0.0, 1.0) var acceleration = 1.0
export (float, 0.0, 0.0, 1.0) var deceleration = 0.1
export var max_speed = Vector3(1.0, 1.0, 1.0)
export var sprint_multiplier = 5
export var local = true
export var forward_action = "ui_up"
export var backward_action = "ui_down"
export var left_action = "ui_left"
export var right_action = "ui_right"
export var up_action = "ui_page_up"
export var down_action = "ui_page_down"
export var look_up = "ui_look_up"
export var look_down = "ui_look_down"
export var look_left = "ui_look_left"
export var look_right = "ui_look_right"
export var sprint_action = "ui_sprint"
export var toggle_wireframe_action = "toggle_wireframe"

# Gui settings
export var use_gui = true
export var gui_action = "ui_cancel"

# Nodes
onready var viewport = get_parent()

# Intern variables.
var _mouse_position = Vector2(0.0, 0.0)
var _controller_position = Vector2(0.0, 0.0)
var _yaw = 0.0
var _pitch = 0.0
var _total_yaw = 0.0
var _total_pitch = 0.0

var _direction = Vector3(0.0, 0.0, 0.0)
var _speed = Vector3(0.0, 0.0, 0.0)
var _gui
var sprinting = false

var vr_on = false
var vrcamera = null
var vrorigin = null
var player_height = 1.7
var walk_mode = false

signal position_updated

func _init():
	# This line is necessary for getting wireframes to work - see https://github.com/godotengine/godot/issues/15149, where I requested clarification.
	# I did not notice a performance drop, but I suspect it is possible that this can cause performance issues. (unforuntately it is not documented at all)
	# Putting this in the same block as 'viewport.debug_draw = Viewport.DEBUG_DRAW_WIREFRAME' did not work - afaik, this is because
		# it needs to be on all the time since wireframes are only created as soon as an object is created.
	# In the future, we might consider implementing a global debug mode which needs to be turned on or off before running the program?
	VisualServer.set_debug_generate_wireframes(true)

func _ready():
	_check_actions([forward_action, backward_action, left_action, right_action, gui_action, up_action, down_action])

	if privot:
		privot = get_node(privot)
	else:
		privot = null

	set_enabled(enabled)

	if use_gui:
		_gui = preload("camera_control_gui.gd")
		_gui = _gui.new(self, gui_action)
		add_child(_gui)

func _input(event):
	if event.is_action_pressed(gui_action):
		if mouse_mode == 2:
			mouse_mode = 0
		else:
			mouse_mode = 2
		Input.set_mouse_mode(mouse_mode)
		mouselook = !mouselook
	
	if mouselook:
		if event is InputEventMouseMotion:
			_mouse_position = event.relative
			if lock_verical_look:
				_mouse_position.y = 0
	if controllerlook:
		if not lock_verical_look:
			if event.is_action_pressed(look_up):
				_controller_position.y = -1
			elif event.is_action_pressed(look_down):
				_controller_position.y = 1
			elif not Input.is_action_pressed(look_up) and not Input.is_action_pressed(look_down):
				_controller_position.y = 0
		else:
			_controller_position.y = 0
		if event.is_action_pressed(look_left):
			_controller_position.x = -1
		elif event.is_action_pressed(look_right):
			_controller_position.x = 1
		elif not Input.is_action_pressed(look_left) and not Input.is_action_pressed(look_right):
			_controller_position.x = 0
	
	if movement:  #TODO rewrite once get_action_strength() is introduced in godot 3.1
		if event.is_action_pressed(forward_action):
			_direction.z = -1
		elif event.is_action_pressed(backward_action):
			_direction.z = 1
		elif not Input.is_action_pressed(forward_action) and not Input.is_action_pressed(backward_action):
			_direction.z = 0
		
		if event.is_action_pressed(left_action):
			_direction.x = -1
		elif event.is_action_pressed(right_action):
			_direction.x = 1
		elif not Input.is_action_pressed(left_action) and not Input.is_action_pressed(right_action):
			_direction.x = 0
			
		if event.is_action_pressed(up_action):
			_direction.y = 1
		if event.is_action_pressed(down_action):
			_direction.y = -1
		elif not Input.is_action_pressed(up_action) and not Input.is_action_pressed(down_action):
			_direction.y = 0
		
		if event.is_action_pressed(sprint_action):
			max_speed *= sprint_multiplier
		elif event.is_action_released(sprint_action):
			max_speed /= sprint_multiplier
	
	# Toggle wireframe mode or normal mode
	if event.is_action_pressed(toggle_wireframe_action):
		if viewport.debug_draw == Viewport.DEBUG_DRAW_DISABLED: # If debug draw is currently off, change to wireframe
			logger.info("Turning wireframes on")
			viewport.debug_draw = Viewport.DEBUG_DRAW_WIREFRAME
		else: # Else (if there currently is a debug draw mode turned on), change to normal
			logger.info("Turning wireframes off")
			viewport.debug_draw = Viewport.DEBUG_DRAW_DISABLED

func _process(delta):
	if privot:
		_update_distance()
	if vr_on and VRNodesValid():
		transform = vrcamera.get_ref().global_transform
	if mouselook or controllerlook:
		_update_mouselook()
	if movement:
		_update_movement(delta)

func _physics_process(delta):
	# Called when collision are enabled
	_update_distance()
	if mouselook or controllerlook:
		_update_mouselook()

	var space_state = get_world().get_direct_space_state()
	var obstacle = space_state.intersect_ray(privot.get_translation(),  get_translation())
	if not obstacle.empty():
		set_translation(obstacle.position)

# TODO might have to check vr movement, I think there could be a bug where you tend to drift lightly upwards while trying to move forward
# could also be my imagination though
func _update_movement(delta):
	var offset = max_speed * acceleration * _direction
	
	_speed.x = clamp(_speed.x + offset.x, -max_speed.x, max_speed.x)
	_speed.y = clamp(_speed.y + offset.y, -max_speed.y, max_speed.y)
	_speed.z = clamp(_speed.z + offset.z, -max_speed.z, max_speed.z)
	
	# Apply deceleration if no input
	if _direction.x == 0:
		_speed.x *= (1.0 - deceleration)
	if _direction.y == 0:
		_speed.y *= (1.0 - deceleration)
	if _direction.z == 0:
		_speed.z *= (1.0 - deceleration)

	if vr_on:
		if VRNodesValid():
			if local:
				#vrorigin.translate(_speed * delta)
				vrorigin.get_ref().transform.origin += vrcamera.get_ref().global_transform.translated(_speed * delta).origin - vrcamera.get_ref().global_transform.origin
				
				#this is probably wrong as it would move the origin relative to origins transform and not vrcameras
			else:
				vrorigin.get_ref().global_translate(_speed * delta)
			if walk_mode:
				transform = vrcamera.get_ref().global_transform
				var hght = get_height_above_ground()
				if hght != null :
					vrorigin.get_ref().global_translate(Vector3(0,player_height - hght, 0))
		else:
			logger.error("vrorigin or vrcamera is null or not in tree")
			getVRNodes()
			pass
	else:
		if local:
			translate(_speed * delta)
		else:
			global_translate(_speed * delta)
		if walk_mode:
			var hght = get_height_above_ground()
			if hght != null:
				global_translate(Vector3(0,player_height - hght, 0))
	emit_signal("position_updated")

func _update_mouselook():
	_mouse_position += _controller_position
	_mouse_position *= sensitivity
	_yaw = _yaw * smoothness + _mouse_position.x * (1.0 - smoothness)
	_pitch = _pitch * smoothness + _mouse_position.y * (1.0 - smoothness)
	_mouse_position = Vector2(0, 0)

	if yaw_limit < 360:
		_yaw = clamp(_yaw, -yaw_limit - _total_yaw, yaw_limit - _total_yaw)
	if pitch_limit < 360:
		_pitch = clamp(_pitch, -pitch_limit - _total_pitch, pitch_limit - _total_pitch)

	_total_yaw += _yaw
	_total_pitch += _pitch

	if privot:
		var target = privot.get_translation()
		var offset = get_translation().distance_to(target)

		set_translation(target)
		rotate_y(deg2rad(-_yaw))
		rotate_object_local(Vector3(1,0,0), deg2rad(-_pitch))
		translate(Vector3(0.0, 0.0, offset))

		if rotate_privot:
			privot.rotate_y(deg2rad(-_yaw))
	else:
		if vr_on:
			if VRNodesValid():
				var t1 = Transform()
				var t2 = Transform()
				var rot = Transform()
				
				t1.origin = -vrcamera.get_ref().transform.origin
				t2.origin = vrcamera.get_ref().transform.origin
				
				# Rotating
				
				if (_yaw > 0.0):
					rot = rot.rotated(Vector3(0.0,-1.0,0.0),_yaw * PI / 180.0)
					
				else:
					rot = rot.rotated(Vector3(0.0,1.0,0.0),-_yaw * PI / 180.0)
				
				vrorigin.get_ref().transform *= t2 * rot * t1
				pass
			else:
				logger.error("vrorigin or vrcamera is null or not in tree")
				getVRNodes()
				pass
		else:
			rotate_y(deg2rad(-_yaw))
			rotate_object_local(Vector3(1,0,0), deg2rad(-_pitch))

func _update_distance():
	var t = privot.get_translation()
	t.z -= distance
	set_translation(t)

func _update_process_func():
	# Use physics process if collision are enabled
	if collisions and privot:
		set_physics_process(true)
		set_process(false)
	else:
		set_physics_process(false)
		set_process(true)

func _check_actions(actions=[]):
	if OS.is_debug_build():
		for action in actions:
			if not InputMap.has_action(action):
				print('WARNING: No action "' + action + '"')

func set_privot(value):
	privot = value
	# TODO: fix parenting.
#	if privot:
#		if get_parent():
#			get_parent().remove_child(self)
#		privot.add_child(self)
	_update_process_func()

func set_collisions(value):
	collisions = value
	_update_process_func()

func set_enabled(value):
	enabled = value
	if enabled:
		Input.set_mouse_mode(mouse_mode)
		set_process_input(true)
		_update_process_func()
	else:
		set_process(false)
		set_process_input(false)
		set_physics_process(false)

func set_smoothness(value):
	smoothness = clamp(value, 0.001, 0.999)

func set_distance(value):
	distance = max(0, value)

func set_vrmode(vrmode):
	vr_on = vrmode
	mouselook = !vr_on
	lock_verical_look = vr_on
	if vr_on:
		getVRNodes()
		if VRNodesValid():
			#teleport vr headset to camera
			vrorigin.get_ref().global_transform.origin = global_transform.origin - vrcamera.get_ref().transform.origin
		
	else:
		vrcamera = null
		vrorigin = null
		set_rotation(Vector3(0,0,0))

func getVRNodes():
	vrcamera = weakref(get_tree().get_root().get_node("main/VRViewport/ARVROrigin/ARVRCamera"))
	vrorigin = weakref(get_tree().get_root().get_node("main/VRViewport/ARVROrigin"))

func VRNodesValid():
	if (vrcamera!=null and vrcamera.get_ref()
	and vrorigin!=null and vrorigin.get_ref()):
			return true
	return false

func teleport(t):
	logger.info("teleporting")
	
	transform = t

func set_walk_mode(new_val):
	walk_mode = new_val
	logger.info("walk mode toggled " + ("on" if walk_mode else "off"))

func get_height_above_ground():
	var position = transform.origin
	var vert = Vector3(0,1000,0)
	#TODO scale vert properly so that it works in every situation
	
	var space_state = get_world().direct_space_state
	var resultUp = space_state.intersect_ray(position, position + vert)
	var resultDown = space_state.intersect_ray(position, position - vert)
	if not resultUp.empty():
		return position.y - resultUp.position.y
	elif not resultDown.empty():
		return position.y - resultDown.position.y
	return null