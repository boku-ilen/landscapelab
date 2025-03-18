extends Window

#
# External window with a camera that follows a dolly rail 
# the rail can be set using controls from the external window
# in windows with action handerls
#

@export var scroll_step := 5.

var action_handlers: Array : set = on_set_handlers
var position_manager: PositionManager
var set_action: DollyAction
var dolly_scene: Node3D = load("res://Util/Imaging/Dolly/DollyScene.tscn").instantiate()
var previous_center_node: Node3D 

@onready var geodata_chooser = $Margin/VBox/ImagingMenu/GeodataOptions/GeodataChooser
@onready var feature_options = $Margin/VBox/ImagingMenu/GeodataOptions/FeatureOptions
@onready var feature_chooser = $Margin/VBox/ImagingMenu/GeodataOptions/FeatureOptions/FeatureChooser
@onready var apply_camera = $Margin/VBox/ImagingMenu/GeodataOptions/FeatureOptions/ApplyButtons/Camera
@onready var apply_focus = $Margin/VBox/ImagingMenu/GeodataOptions/FeatureOptions/ApplyButtons/Focus

# DollyAction
# primary action => set point
# secondary action => set focus
# tertiary action => close path to a ring
class DollyAction extends EditingAction:
	func add_point(input: InputEvent, cursor, state_dict: Dictionary, path):
		var pos: Vector3 = cursor.get_cursor_engine_position()
		
		# In order to give usability feedback we add two points 
		# The first one is the set point, the second one will show where the path would lead
		if path.point_count == 0:
			path.add_point(pos + Vector3.UP * height_correction)
			# Avoid points having the same coordinates - errors otherwise
			path.add_point(pos + Vector3.UP * height_correction + Vector3.FORWARD)
			return
		
		var height_corrected_point = pos + Vector3.UP * height_correction
		path.set_point_position(path.point_count - 1, height_corrected_point)
		path.add_point(height_corrected_point)
	
	func close_path(input: InputEvent, cursor, state_dict: Dictionary):
		var path: Curve3D = dolly_scene.path
		path.set_point_position(path.point_count - 1, path.get_point_position(0))
		path.tessellate_even_length()
		is_closed = true
	
	var dolly_scene: Node3D
	var is_closed = false
	
	var height_correction := 0.0 : set = set_height_correction
	func set_height_correction(new_height): height_correction = new_height
	
	func _init(new_dolly_scene):
		dolly_scene = new_dolly_scene
		super._init(
			func(i, c, sd): add_point(i, c, sd, dolly_scene.path), 
			func(i, c, sd): add_point(i, c, sd, dolly_scene.focus_path), 
			close_path, 
			true)
	
	func special_action(event: InputEvent, cursor):
		# Give user feedback to where the path will be
		if event is InputEventMouseMotion:
			var path: Curve3D = dolly_scene.path
			if path.point_count < 1 or is_closed: return
			
			var pos: Vector3 = cursor.get_cursor_engine_position()
			path.set_point_position(path.point_count - 1, pos + Vector3.UP * height_correction)


func _ready():
	apply_camera.pressed.connect(apply_curve3D_to_path.bind("path"))
	apply_focus.pressed.connect(apply_curve3D_to_path.bind("focus_path"))


func apply_curve3D_to_path(path_name: String):
	var feature: GeoLine = feature_chooser.get_currently_selected_feature()
	if not feature is GeoLine: return
	
	var center: Array = position_manager.get_center()
	
	# Obtain the actual geo positions (curve does not have an option to get the unbaked points
	# unfortunately)
	var geo_points = []
	var geo_curve = feature.get_curve3d()
	geo_points.resize(geo_curve.point_count)
	for i in geo_curve.point_count:
		geo_points[i] = geo_curve.get_point_position(i)
	
	# Now sample on the DTM
	geo_points = GeoUtil.sample_points_on_height_model(
		geo_points, 
		Layers.layer_compositions["Terrain"].render_info.height_layer,
		true
	)
	
	# And apply back to the engine curve
	var engine_curve: Curve3D = feature.get_offset_curve3d(-center[0], 0, -center[1])
	for i in geo_points.size():
		var pos = engine_curve.get_point_position(i)
		pos.y = geo_points[i].y
		engine_curve.set_point_position(i, pos)
	
	dolly_scene.set(path_name, engine_curve)


func on_set_handlers(handlers):
	action_handlers = handlers
	
	# Create dolly scene and add to tree
	$Margin/VBox/SubViewportContainer/SubViewport.add_child(dolly_scene)
	
	# Create the set action for new handlers
	set_action = DollyAction.new(dolly_scene)
	
	# Connect ui-controls with the new action
	# The height at which the newly set point of the dollyrail will be above ground
	var spinbox = $Margin/VBox/ImagingMenu/VBoxContainer/SpinBox
	spinbox.value_changed.connect(set_action.set_height_correction)
	# Set with initial value
	set_action.set_height_correction(spinbox.value)
	
	# Clears the set path
	var clear = $Margin/VBox/ImagingMenu/GridContainer/Clear
	clear.pressed.connect(set_action.dolly_scene.clear)
	clear.pressed.connect(func(): set_action.is_closed = false)
	
	# Enables the set action for action handlers
	$Margin/VBox/ImagingMenu/GridContainer/Set
	var set_button = $Margin/VBox/ImagingMenu/GridContainer/Set
	for handler in action_handlers:
		set_button.toggled.connect(func(toggled: bool):
			if toggled: handler.set_current_action(set_action)
			else: handler.stop_current_action())
	
	# If the button is toggled, the camera will follow the set focus
	var focus = $Margin/VBox/ImagingMenu/GridContainer/Focus
	focus.toggled.connect(enable_focus)
	
	# Change whether the dolly_camera is center node or not
	var toggle_center = $Margin/VBox/ImagingMenu/GridContainer/CenterNode
	toggle_center.toggled.connect(func(toggled): 
		if toggled: toggle_center_node(dolly_scene.dolly_cam)
		else: 		toggle_center_node(previous_center_node))


func toggle_center_node(new_center_node: Node3D):
	# Swap center node
	previous_center_node = position_manager.center_node
	position_manager.center_node = new_center_node


func enable_focus(toggled: bool):
	dolly_scene.dolly_cam.focus_enabled = toggled


# For usability reasons let the height_correction be controlled via mouse wheel
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			$Margin/VBox/ImagingMenu/VBoxContainer/SpinBox.value += scroll_step
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			$Margin/VBox/ImagingMenu/VBoxContainer/SpinBox.value -= scroll_step
	
