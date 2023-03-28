extends Window


var action_handlers: Array
@onready var set_action = DollySetAction.new($Margin/VBox/SubViewportContainer/SubViewport)


func _ready():
	# set initial height correction
	set_action.set_height_correction($Margin/VBox/ImagingMenu/VBoxContainer/SpinBox.value)
	for handler in action_handlers:
		$Margin/VBox/ImagingMenu/Set.toggled.connect(func(toggled: bool):
			if toggled: handler.set_current_action(set_action)
			else: handler.stop_current_action())
	$Margin/VBox/ImagingMenu/Clear.pressed.connect(set_action.dolly_scene.clear)
	$Margin/VBox/ImagingMenu/VBoxContainer/SpinBox.value_changed.connect(set_action.set_height_correction)


class DollySetAction extends EditingAction:
	var set_focus = func(input: InputEvent, cursor, state_dict: Dictionary): 
		var pos = cursor.get_cursor_engine_position()
		dolly_scene.set_focus_position(pos, Vector3.UP * height_correction)
	var add_point = func(input: InputEvent, cursor, state_dict: Dictionary):
		var pos = cursor.get_cursor_engine_position()
		dolly_scene.add_path_point(pos + Vector3.UP * height_correction)
		point_count = point_count + 1
		dolly_scene.get_node("DollyRail/PathFollow3D/RemoteTransform3D").remote_path = dolly_cam.get_path()
		dolly_scene.toggle_cam(point_count > 1)
	
	# FIXME: this logic should be rewritten to be a line-feature
	var dolly_scene = load("res://Util/Imaging/Dolly/DollyScene.tscn").instantiate()
	var dolly_cam = load("res://Util/Imaging/Dolly/DollyCamera.tscn").instantiate()
	
	var height_correction := 0.0 : set = set_height_correction
	var point_count := 0
	
	func set_height_correction(value: float): 
		height_correction = value
	
	func _init(viewport):
		super._init(add_point, set_focus)
		dolly_scene.dolly_cam = dolly_cam
		viewport.add_child(dolly_scene)
		viewport.add_child(dolly_cam)
