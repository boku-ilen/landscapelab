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

var profile = preload("res://UI/Layers/LayerConfiguration/Misc/ProfileEditor/Profile.tscn")
var poly_point = preload("res://UI/Layers/LayerConfiguration/Misc/ProfileEditor/PolygonPoint.tscn")
var current_point setget set_current_point
var current_profile: CSGPolygon setget set_current_profile
var current_object: Spatial setget set_current_object
var is_dragging: bool = false
var is_stiring: bool = false
var current_view: int

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
	$HSplitContainer/ViewportContainer/VBoxContainer/ElevationViewButton.connect("pressed", self, "_change_view", [Views.ELEVATION])
	$HSplitContainer/ViewportContainer/VBoxContainer/PlanViewButton.connect("pressed", self, "_change_view", [Views.PLAN])
	$HSplitContainer/ViewportContainer/VBoxContainer/PerspectiveViewButton.connect("pressed", self, "_change_view", [Views.PERSPECTIVE])
	
	# Profile
	connect("current_profile_changed", profile_menu, "set_current_profile")
	profile_menu.get_node("AddProfileButton").connect("pressed", profile_menu, "_add_profile", [profile, path])
	
	# Points
	connect("current_profile_changed", point_menu, "set_current_profile")
	connect("current_point_changed", point_menu, "set_current_point")
	point_menu.get_node("AddPointButton").connect("pressed", point_menu, "_add_point", [poly_point])
	
	# Objects
	object_menu.get_node("ObjectChooser/AddObject").connect("pressed", object_menu, "_add_object", [viewport])
	object_menu.get_node("ScalingBox/Apply").connect("pressed", object_menu, "_scale_object")
	
	# Saving
	$HSplitContainer/Vbox/SaveButton.connect("pressed", save_menu, "popup")
	save_menu.connect("file_selected", save_menu, "save", [path])


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
	var projected_mouse = camera.project_ray_origin(viewport.get_viewport().get_mouse_position())
	var from = camera.to_local(projected_mouse)
	var to = from + camera.project_local_ray_normal(viewport.get_viewport().get_mouse_position()) * 100
	cursor.set_translation(from)
	cursor.set_cast_to(to)
	# Dragging functionality of the polygon points
	if event is InputEventMouseButton:
		if is_event_inside_control(event, viewport_container):
			_focus_point(event)
			if event.button_index == BUTTON_WHEEL_UP:
				_scroll(true)
			elif event.button_index == BUTTON_WHEEL_DOWN:
				_scroll(false)
		if event.button_index == BUTTON_MIDDLE:
			is_stiring = event.is_pressed()
	elif event is InputEventMouseMotion:
		if is_dragging and current_point:
			_drag_polygon(event, projected_mouse)
		elif is_stiring:
			_stir(event)


func _focus_point(event: InputEvent):
	if event.is_pressed() and event.button_index == BUTTON_LEFT:
		is_dragging = true
		if cursor.is_colliding() and cursor.get_collider() is PolygonPoint:
			set_current_point(cursor.get_collider())
			set_current_profile(current_point.get_parent())
		else:
			if cursor.is_colliding():
				set_current_object(cursor.get_collider())
			set_current_point(null)
			set_current_profile(null)
	else:
		is_dragging = false


func _drag_polygon(event: InputEvent, projected_mouse):
	if camera.projection == Camera.PROJECTION_ORTHOGONAL:
		var new_pos
		if current_view == Views.ELEVATION:
			new_pos = Vector2(projected_mouse.x, projected_mouse.y)
		else:
			new_pos = Vector2(projected_mouse.x, current_point.position.y)
		current_point.set_position(new_pos)
		current_profile.drag()
	else:
		var distance = camera.project_ray_origin(viewport.get_viewport().get_mouse_position()).distance_to(current_point.translation)
		var relative_proj = camera.project_ray_normal(viewport.get_viewport().get_mouse_position()) * distance
		var new_pos = Vector2(relative_proj.x, relative_proj.y)
		current_point.set_position(new_pos)
		current_profile.drag()


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


func set_current_point(point):
	if current_point:
		current_point.color = Color.red
	
	emit_signal("current_point_changed", point)
	current_point = point
	
	if current_point:
		current_point.color = Color.green


func set_current_profile(profile):
	if current_profile:
		current_profile.color = Color.red
		
	emit_signal("current_profile_changed", profile)
	current_profile = profile
	
	if current_profile:
		current_profile.color = Color.green


func set_current_object(object):
	emit_signal("current_object_changed", object)
	current_object = object
