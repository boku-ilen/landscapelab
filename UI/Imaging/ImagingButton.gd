extends "res://UI/Tools/ToolsButton.gd"


var pc_player: AbstractPlayer :
	get:
		return pc_player
	set(player):
		pc_player = player
		
		var camera = load("res://Util/Imaging/Dolly/DollyCamera.tscn").instantiate()
		var scene = load("res://Util/Imaging/Dolly/DollyScene.tscn").instantiate()
		scene.set_cam(camera)
		_set_imaging_action(ImagingAction.new(
			pc_player.action_handler.cursor, 
			scene,
			camera,
			pc_player, true))
		
		set_height_correction($Window/ImagingMenu/VBoxContainer/SpinBox.value)

var pos_manager: PositionManager :
	get:
		return pos_manager
	set(pos_man):
		pos_manager = pos_man
		imaging_action.world = pos_man.get_parent() # FIXME: Ugly

var main_ui: Control
var imaging_action: ImagingAction 


func _ready():
	# Once ready, this child is already appended to its popup
	$ImagingMenu/VBoxContainer/SpinBox.connect(
		"value_changed", set_height_correction)
	$ImagingMenu/Set.connect("toggled",Callable(self,"_toggle_set_dolly_path"))


func _set_imaging_action(new_imaging_action):
	# Disconnect the old connections
	if imaging_action:
		if $Window/ImagingMenu/Show.is_connected("toggled",Callable(imaging_action,"set_imaging_visible")):
			$Window/ImagingMenu/Show.disconnect("toggled",Callable(imaging_action,"set_imaging_visible"))
		if $Window/ImagingMenu/Clear.is_connected("pressed",Callable(imaging_action,"clear")):
			$Window/ImagingMenu/Clear.disconnect("pressed",Callable(imaging_action,"clear"))
	
	imaging_action = new_imaging_action
	$Window/ImagingMenu/Show.connect("toggled",Callable(imaging_action,"set_imaging_visible"))
	$Window/ImagingMenu/Clear.connect("pressed",Callable(imaging_action,"clear"))


func _toggle_set_dolly_path(button_pressed: bool):
	if button_pressed:
		pc_player.action_handler.set_current_action(imaging_action)
	else:
		pc_player.action_handler.stop_current_action()


func set_height_correction(height: float):
	imaging_action.height_correction = height


class ImagingAction extends ActionHandler.Action:
	var cursor
	var world: Node3D :
		get:
			return world
		set(pos_manager):
			# FIXME: This is ugly
			player_camera = world.get_viewport().get_camera_3d()
			world.add_child(dolly_scene)
			world.add_child(dolly_camera)
			player_camera.make_current()
	
	var height_correction
	var dolly_scene: Node3D
	var dolly_camera: Camera3D
	var player_camera: Camera3D
	var point_count := 0 :
		get:
			return point_count 
		set(count):
			point_count = count
			toggle_cam(point_count > 1)
	
	
	func _init(c,rail: Node3D,cam: Camera3D,p,b):
		super._init(p, b)
		
		cursor = c
		dolly_scene = rail
		dolly_camera = cam
	
	
	func toggle_cam(enable: bool):
		dolly_scene.get_node("DollyRail/PathFollow3D/RemoteTransform3D").remote_path = dolly_camera.get_path()
		if dolly_scene != null:
			dolly_scene.toggle_cam(enable)


	func clear():
		dolly_scene.clear()
		self.point_count = 0
	
	
	func set_imaging_visible(toggled: bool):
		if toggled:
			dolly_camera.make_current()
		else:
			player_camera.make_current()
	
	
	func apply(event):
		var collision_position = cursor.get_collision_point()
		if event.is_action_pressed("imaging_set_path"):
			dolly_scene.add_path_point(collision_position + Vector3.UP * height_correction)
			self.point_count = point_count + 1
		elif event.is_action_pressed("imaging_set_focus"):
			dolly_scene.set_focus_position(collision_position, Vector3.UP * height_correction)
