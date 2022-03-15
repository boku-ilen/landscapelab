extends "res://UI/Tools/ToolsButton.gd"


var pc_player: AbstractPlayer setget set_player
var pos_manager: PositionManager setget set_pos_man
var main_ui: Control
var imaging_action: ImagingAction 


func _ready():
	# Once ready, this child is already appended to its popup
	$WindowDialog/ImagingMenu/VBoxContainer/SpinBox.connect(
		"value_changed", self, "set_height_correction")
	$WindowDialog/ImagingMenu/Set.connect("toggled", self, "_toggle_set_dolly_path")


func _set_imaging_action(new_imaging_action):
	# Disconnect the old connections
	if imaging_action:
		if $WindowDialog/ImagingMenu/Show.is_connected("toggled", imaging_action, "set_imaging_visible"):
			$WindowDialog/ImagingMenu/Show.disconnect("toggled", imaging_action, "set_imaging_visible")
		if $WindowDialog/ImagingMenu/Clear.is_connected("pressed", imaging_action, "clear"):
			$WindowDialog/ImagingMenu/Clear.disconnect("pressed", imaging_action, "clear")
	
	imaging_action = new_imaging_action
	$WindowDialog/ImagingMenu/Show.connect("toggled", imaging_action, "set_imaging_visible")
	$WindowDialog/ImagingMenu/Clear.connect("pressed", imaging_action, "clear")


func _toggle_set_dolly_path(button_pressed: bool):
	if button_pressed:
		pc_player.action_handler.set_current_action(imaging_action)
	else:
		pc_player.action_handler.stop_current_action()


func set_player(player):
	pc_player = player
	
	var camera = load("res://Util/Imaging/Dolly/DollyCamera.tscn").instance()
	var scene = load("res://Util/Imaging/Dolly/DollyScene.tscn").instance()
	scene.set_cam(camera)
	_set_imaging_action(ImagingAction.new(
		pc_player.action_handler.cursor, 
		scene,
		camera,
		pc_player, true))
	
	set_height_correction($WindowDialog/ImagingMenu/VBoxContainer/SpinBox.value)


func set_pos_man(pos_man):
	pos_manager = pos_man
	imaging_action.world = pos_man


func set_height_correction(height: float):
	imaging_action.height_correction = height


class ImagingAction extends ActionHandler.Action:
	var cursor
	var world: Spatial setget set_world
	var height_correction
	var dolly_scene: Spatial
	var dolly_camera: Camera
	var player_camera: Camera
	var point_count := 0 setget set_point_count
	
	
	func _init(c, rail: Spatial, cam: Camera, p, b).(p, b):
		cursor = c
		dolly_scene = rail
		dolly_camera = cam
		return dolly_scene
	
	
	func set_point_count(count: int):
		point_count = count
		toggle_cam(point_count > 1)
	
	
	func toggle_cam(enable: bool):
		dolly_scene.get_node("DollyRail/PathFollow/RemoteTransform").remote_path = dolly_camera.get_path()
		if dolly_scene != null:
			dolly_scene.toggle_cam(enable)


	func set_world(pos_manager):
		# FIXME: This is ugly
		world = pos_manager.get_parent()
		player_camera = world.get_viewport().get_camera()
		world.add_child(dolly_scene)
		world.add_child(dolly_camera)
		player_camera.make_current()


	func clear():
		dolly_scene.clear()
		set_point_count(0)
	
	
	func set_imaging_visible(toggled: bool):
		if toggled:
			dolly_camera.make_current()
		else:
			player_camera.make_current()
	
	
	func apply(event):
		var position = cursor.get_collision_point()
		if event.is_action_pressed("imaging_set_path"):
			dolly_scene.add_path_point(position + Vector3.UP * height_correction)
			set_point_count(point_count + 1)
		elif event.is_action_pressed("imaging_set_focus"):
			dolly_scene.set_focus_position(position, Vector3.UP * height_correction)
