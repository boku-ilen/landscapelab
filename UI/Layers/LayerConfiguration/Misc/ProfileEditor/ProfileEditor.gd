extends WindowDialog


onready var viewport = get_node("HSplitContainer/ViewportContainer/Viewport")
onready var viewport_container = get_node("HSplitContainer/ViewportContainer")
onready var camera = get_node("HSplitContainer/ViewportContainer/Viewport/Spatial/Camera")
onready var cursor = get_node("HSplitContainer/ViewportContainer/Viewport/Spatial/Camera/MousePoint")
onready var path = get_node("HSplitContainer/ViewportContainer/Viewport/Spatial/Path")

onready var save_menu = get_node("HSplitContainer/Vbox/SaveButton/SaveMenu")
onready var profile_menu = get_node("HSplitContainer/Vbox/ScrollContainer/Vbox/ProfileContainer")
onready var point_menu = get_node("HSplitContainer/Vbox/ScrollContainer/Vbox/PointContainer")
onready var object_menu = get_node("HSplitContainer/Vbox/ScrollContainer/Vbox/ObjectContainer")
onready var objects = get_node("HSplitContainer/ViewportContainer/Viewport/Spatial/Objects")

onready var drag_handler = get_node("DragHandler")

var profile = preload("res://UI/Layers/LayerConfiguration/Misc/ProfileEditor/Profile.tscn")
var poly_point = preload("res://UI/Layers/LayerConfiguration/Misc/ProfileEditor/PolygonPoint.tscn")
var current_view: int

var is_dragging: bool = false
var is_stiring: bool = false
var is_snapping: bool = false
var is_snapping_grid: bool = false

signal current_profile_changed(profile)
signal current_point_changed(point)
signal current_object_changed(object)

enum Views {
	ELEVATION,
	PLAN,
	PERSPECTIVE
}


func _ready():
	popup()
	
	# Viewing
	_change_view(Views.ELEVATION)
	var button_box = $HSplitContainer/ViewportContainer/VBoxContainer
	button_box.get_node("ElevationViewButton").connect("pressed", self, "_change_view", [Views.ELEVATION])
	button_box.get_node("PlanViewButton").connect("pressed", self, "_change_view", [Views.PLAN])
	button_box.get_node("PerspectiveViewButton").connect("pressed", self, "_change_view", [Views.PERSPECTIVE])
	
	# Profile
	connect("current_profile_changed", profile_menu, "set_current_profile")
	profile_menu.get_node("AddProfileButton").connect("pressed", profile_menu, 
		"_add_profile", [profile, path, drag_handler])
	
	# Points
	connect("current_profile_changed", point_menu, "set_current_profile")
	connect("current_point_changed", point_menu, "set_current_point")
	point_menu.get_node("AddPointButton").connect("pressed", point_menu, 
		"_add_point", [poly_point, drag_handler])
	
	# Objects
	connect("current_object_changed", object_menu, "set_current_object")
	object_menu.get_node("ObjectChooser/AddObject").connect("pressed", object_menu, 
		"_add_object", [objects, drag_handler])
	object_menu.get_node("DistanceBox/Apply").connect("pressed", object_menu, 
		"_apply_reoccuring_object", [path])
	
	# Saving
	$HSplitContainer/Vbox/SaveButton.connect("pressed", save_menu, "popup")
	save_menu.connect("file_selected", save_menu, "save", [path])


# Changes view depending on the current Views-enum
func _change_view(view_type: int):
	current_view = view_type
	camera.transform = Transform.IDENTITY
	if view_type == Views.ELEVATION:
		camera.projection = camera.PROJECTION_ORTHOGONAL
		camera.translation = Vector3(0, 0, 3.665)
		camera.rotation_degrees = Vector3.ZERO
	elif view_type == Views.PLAN:
		camera.projection = camera.PROJECTION_ORTHOGONAL
		camera.translation = Vector3(0, 6, -3)
		camera.rotation_degrees = Vector3(-90,0,0)
	elif view_type == Views.PERSPECTIVE:
		camera.projection = camera.PROJECTION_PERSPECTIVE
		camera.translation = Vector3(6, 6, 8)
		camera.look_at(Vector3.ZERO, Vector3.UP)


func _input(event):
	# Proper mouse position (both for orthogonal/perspective)
	var projected_mouse = camera.project_ray_origin(viewport.get_viewport().get_mouse_position())
	var from = camera.to_local(projected_mouse)
	var to = from + camera.project_local_ray_normal(viewport.get_viewport().get_mouse_position()) * 100
	cursor.set_translation(from)
	cursor.set_cast_to(to)
	
	# Snap to other object corners
	if event.is_action_pressed("snapping"):
		is_snapping = true
	if event.is_action_released("snapping"):
		is_snapping = false
	# Snap to grid
	if event.is_action_pressed("snapping_grid"):
		is_snapping_grid = true
	if event.is_action_released("snapping_grid"):
		is_snapping_grid = false
		
	# Focus objects/polygons/polygon-points
	if event is InputEventMouseButton:
		if is_event_inside_control(event, viewport_container):
			_focus(event)
			if event.button_index == BUTTON_WHEEL_UP:
				_scroll(true)
			elif event.button_index == BUTTON_WHEEL_DOWN:
				_scroll(false)
		if event.button_index == BUTTON_MIDDLE:
			is_stiring = event.is_pressed()
	# Drag them around or stir 
	elif event is InputEventMouseMotion:
		if is_dragging and drag_handler.current_dragable:
			drag_handler.drag(_get_cursor_pos(projected_mouse, drag_handler.current_dragable))
		elif is_stiring:
			_stir(event)


func _focus(event: InputEvent):
	if event.is_pressed() and event.button_index == BUTTON_LEFT:
		is_dragging = true
		if cursor.is_colliding():
			drag_handler.set_current_dragable(cursor.get_collider())
		else:
			drag_handler.set_current_dragable(null)
	elif event.is_pressed() and event.button_index == BUTTON_RIGHT:
		is_dragging = true
		if cursor.is_colliding():
			drag_handler.set_current_dragable(cursor.get_collider())
		else:
			drag_handler.set_current_dragable(null)
	else:
		is_dragging = false


# Get the cursor position (dependent on the current view)
func _get_cursor_pos(projected_mouse, currently_selected):
	var new_pos
	if camera.projection == Camera.PROJECTION_ORTHOGONAL:
		if current_view == Views.ELEVATION:
			new_pos = Vector2(projected_mouse.x, projected_mouse.y)
		else:
			new_pos = Vector2(projected_mouse.x, currently_selected.position.y)
	else:
		var distance = camera.project_ray_origin(viewport.get_viewport().get_mouse_position()).distance_to(currently_selected.position)
		var pers_pos = camera.project_ray_normal(viewport.get_viewport().get_mouse_position()) * distance
		new_pos = Vector2(pers_pos.x, pers_pos.y)
		
	if is_snapping:
		return drag_handler.snap_objects(new_pos, path.get_children())
	elif is_snapping_grid:
		return drag_handler.snap_grid(new_pos)
	else: 
		return new_pos


func _scroll(up: bool):
	if current_view == Views.PERSPECTIVE:
		if up:
			camera.translation -= Vector3.ONE * camera.transform.basis.z
		else:
			camera.translation += Vector3.ONE * camera.transform.basis.z
	else:
		if up:
			camera.size -= 1
		else:
			camera.size += 1


func _stir(event: InputEventMouseMotion):
	var force = Vector3(-event.relative.x, event.relative.y, 0) * 0.01
	camera.translate(force)


func is_event_inside_control(event: InputEvent, control: Control):
	var window_bounds_y = control.rect_global_position.y + control.rect_size.y 
	var window_bounds_x = control.rect_global_position.x + control.rect_size.x 
	if window_bounds_y > event.position.y and window_bounds_x > event.position.x:
		return true
	else:
		return false
