extends WindowDialog


onready var viewport = get_node("HSplitContainer/ViewportContainer/Viewport")
onready var viewport_container = get_node("HSplitContainer/ViewportContainer")
onready var camera = get_node("HSplitContainer/ViewportContainer/Viewport/Spatial/Camera")
onready var path = get_node("HSplitContainer/ViewportContainer/Viewport/Spatial/Path")
onready var cursor = get_node("HSplitContainer/ViewportContainer/Viewport/Spatial/Camera/MousePoint")
onready var new_profile_button = get_node("HSplitContainer/Vbox/AddProfileButton")
onready var remove_profile_button = get_node("HSplitContainer/Vbox/RemoveProfileButton")
onready var change_view_button = get_node("HSplitContainer/Vbox/ChangeViewButton")
onready var add_point_button = get_node("HSplitContainer/Vbox/AddPointButton")
onready var remove_point_button = get_node("HSplitContainer/Vbox/RemovePointButton")
onready var add_texture_button = get_node("HSplitContainer/Vbox/FileChooser/AddText")

var profile = preload("res://UI/Layers/Misc/ProfileEditor/Profile.tscn")
var poly_point = preload("res://UI/Layers/Misc/ProfileEditor/PolygonPoint.tscn")
var top_view: bool = false
var current_point
var current_profile: CSGPolygon
var is_dragging: bool = false


func _ready():
	popup()
	
	new_profile_button.connect("pressed", self, "_add_profile")
	remove_profile_button.connect("pressed", self, "_remove_profile")
	change_view_button.connect("pressed", self, "_change_view")
	add_point_button.connect("pressed", self, "_add_point")
	remove_point_button.connect("pressed", self, "_remove_point")
	add_texture_button.connect("pressed", self, "_add_texture")


func _add_texture():
	var texture = load(get_node("HSplitContainer/Vbox/FileChooser/FileName").text)
	current_profile.material_override.albedo_texture = texture


func _add_point():
	if current_profile:
		current_profile.add_point(poly_point.instance())


func _remove_point():
	if current_point:
		current_profile.delete_point(current_point.idx)


func _add_profile():
	var new_prof = profile.instance()
	path.add_child(new_prof)
	new_prof.path_node = "../"
	


func _remove_profile():
	if current_profile:
		current_profile.queue_free()
		current_profile = null


func _change_view():
	if top_view:
		camera.translation = Vector3(0, 0, 3.665)
		camera.rotation_degrees.x = 0
		top_view = false
	else:
		camera.translation = Vector3(0, 6, -3)
		camera.rotation_degrees.x = -90
		top_view = true


func _input(event):
	var mouse_pos = viewport.get_viewport().get_mouse_position()
	if event is InputEventMouseButton and is_event_inside_control(event, viewport_container):
		if event.pressed:
			is_dragging = true
			if cursor.is_colliding():
				if current_point:
					current_point.color = Color(1, 0.227451, 0)
				current_point = cursor.get_collider()
				current_profile = current_point.get_parent()
				current_point.color = Color(0, 1, 0.261719)
			else:
				if current_point:
					current_point.color = Color(1, 0.227451, 0)
				current_point = null
		else:
			is_dragging = false
	elif event is InputEventMouseMotion:
		var from = camera.to_local(camera.project_ray_origin(mouse_pos))
		var to = from + camera.project_local_ray_normal(mouse_pos) * 100
		cursor.set_translation(from)
		cursor.set_cast_to(to)
		if is_dragging and current_point:
			if camera.projection == Camera.PROJECTION_ORTHOGONAL:
				var new_pos = Vector2(camera.project_ray_origin(mouse_pos).x, camera.project_ray_origin(mouse_pos).y)
				current_point.set_position(new_pos)
				current_profile.drag()
			else:
				var distance = camera.project_ray_origin(mouse_pos).distance_to(current_point.translation)
				var relative_proj = camera.project_ray_normal(mouse_pos) * distance
				var new_pos = Vector2(relative_proj.x, relative_proj.y)
				current_point.set_position(new_pos)
				current_profile.drag()


func is_event_inside_control(event: InputEvent, control: Control):
	var window_bounds_y = control.rect_global_position.y + control.rect_size.y 
	var window_bounds_x = control.rect_global_position.x + control.rect_size.x 
	if window_bounds_y > event.position.y and window_bounds_x > event.position.x:
		return true
	else:
		return false
