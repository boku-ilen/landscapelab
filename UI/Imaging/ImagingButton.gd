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
	$WindowDialog/ImagingMenu/Show.connect("toggled", imaging_action, "set_imaging_visible")


func _toggle_set_dolly_path(button_pressed: bool):
	if button_pressed:
		pc_player.action_handler.set_current_action(imaging_action)
	else:
		pc_player.action_handler.stop_current_action()


func set_player(player):
	pc_player = player
	imaging_action = ImagingAction.new(pc_player.action_handler.cursor, 
		preload("res://Util/Imaging/DrawPath/Path/Path.tscn"), pc_player, true)
	set_height_correction($WindowDialog/ImagingMenu/VBoxContainer/SpinBox.value)
	$WindowDialog/ImagingMenu/Clear.connect("pressed", imaging_action, "clear")
	$WindowDialog/ImagingMenu/Show.connect("toggled", imaging_action, "set_imaging_visible")


func set_pos_man(pos_man):
	pos_manager = pos_man
	imaging_action.world = pos_man


func set_height_correction(height: float):
	imaging_action.height_correction = height


class ImagingAction extends ActionHandler.Action:
	var cursor
	var world setget set_world
	var height_correction
	var path_scene
	var path_scene_instance
	var point_count := 0 setget set_point_count
	
	
	func _init(c, packed_scene, p, b).(p, b):
		cursor = c
		path_scene = packed_scene
		path_scene_instance = packed_scene.instance()
		return path_scene_instance

	
	func set_point_count(count: int):
		point_count = count
		toggle_cam(point_count > 1)
	
	
	func toggle_cam(enable: bool):
		if path_scene_instance != null:
			path_scene_instance.toggle_cam(enable)


	func set_world(pos_manager):
		world = pos_manager
		world.add_child(path_scene_instance)


	func clear():
		path_scene_instance.clear()
		set_point_count(0)
	
	
	func set_imaging_visible(toggled: bool):
		path_scene_instance.set_imaging_visible(toggled)
	
	
	func apply(event):
		var position = cursor.get_collision_point()
		if event.is_action_pressed("imaging_set_path"):
			path_scene_instance.add_path_point(position + Vector3.UP * height_correction)
			set_point_count(point_count + 1)
		elif event.is_action_pressed("imaging_set_focus"):
			path_scene_instance.set_focus_position(position, Vector3.UP * height_correction)
