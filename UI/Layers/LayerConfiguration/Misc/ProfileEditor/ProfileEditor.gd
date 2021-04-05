extends WindowDialog


onready var viewport = get_node("HSplitContainer/ViewportContainer/Viewport")
onready var viewport_container = get_node("HSplitContainer/ViewportContainer")
onready var camera = get_node("HSplitContainer/ViewportContainer/Viewport/Spatial/Camera")
onready var cursor = get_node("HSplitContainer/ViewportContainer/Viewport/Spatial/Camera/MousePoint")
onready var path = get_node("HSplitContainer/ViewportContainer/Viewport/Spatial/Path")

onready var save_menu = get_node("HSplitContainer/Vbox/SaveButton/SaveMenu")

var profile = preload("res://UI/Layers/LayerConfiguration/Misc/ProfileEditor/Profile.tscn")
var poly_point = preload("res://UI/Layers/LayerConfiguration/Misc/ProfileEditor/PolygonPoint.tscn")
var current_point
var current_profile: CSGPolygon
var is_dragging: bool = false

enum Views {
	ELEVATION,
	PLAN,
	PERSPECTIVE
}


func _ready():
	popup()
	_change_view(Views.ELEVATION)
	$HSplitContainer/Vbox/AddProfileButton.connect("pressed", self, "_add_profile")
	$HSplitContainer/Vbox/RemoveProfileButton.connect("pressed", self, "_remove_profile")
	$HSplitContainer/ViewportContainer/VBoxContainer/ElevationViewButton.connect("pressed", self, "_change_view", [Views.ELEVATION])
	$HSplitContainer/ViewportContainer/VBoxContainer/PlanViewButton.connect("pressed", self, "_change_view", [Views.PLAN])
	$HSplitContainer/ViewportContainer/VBoxContainer/PerspectiveViewButton.connect("pressed", self, "_change_view", [Views.PERSPECTIVE])
	$HSplitContainer/Vbox/AddPointButton.connect("pressed", self, "_add_point")
	$HSplitContainer/Vbox/SaveButton.connect("pressed", save_menu, "popup")
	save_menu.connect("file_selected", self, "_save")
	$HSplitContainer/Vbox/RemovePointButton.connect("pressed", self, "_remove_point")
	$HSplitContainer/Vbox/FileChooser/AddText.connect("pressed", self, "_add_texture")


func _save(file_path: String):
	# Explicitly mark ownership on the parent node, else the children don't get
	# stored in a packed scene
	var i = 0
	for child in path.get_children():
		# The attached profile has editor functionality (drag polygon, etc.)
		# - thus a primitive duplicate is created
		if child.has_method("duplicate_as_primitive_material"):
			var duplicate: CSGPolygon = child.duplicate_as_primitive_material()
			path.add_child(duplicate)
			duplicate.set_owner(path)
			
			# Additionally store the material of each profile
			var resource_path = "%s%d%s" % [file_path.substr(0, file_path.find_last(".")), i, "tres"]
			ResourceSaver.save(resource_path, child.material)
			var mat = SpatialMaterial.new()
			mat.resource_path = resource_path
			duplicate.material = mat
			i += 1
		else:
			child.set_owner(path)
	
	# Store in a packed scene
	var packed_scene = PackedScene.new()
	packed_scene.pack(path)
	ResourceSaver.save(file_path, packed_scene)


func _add_texture():
	var texture = load(get_node("HSplitContainer/Vbox/FileChooser/FileName").text)
	var mat = SpatialMaterial.new()
	mat.albedo_texture = texture
	current_profile.material = mat


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


func _change_view(view_type: int):
	if view_type == Views.PLAN:
		camera.projection = camera.PROJECTION_ORTHOGONAL
		camera.translation = Vector3(0, 0, 3.665)
		camera.rotation_degrees = Vector3.ZERO
	elif view_type == Views.ELEVATION:
		camera.projection = camera.PROJECTION_ORTHOGONAL
		camera.translation = Vector3(0, 6, -3)
		camera.rotation_degrees = Vector3(-90,0,0)
	elif view_type == Views.PERSPECTIVE:
		camera.projection = camera.PROJECTION_PERSPECTIVE
		camera.translation = Vector3(6, 6, 8)
		camera.look_at(Vector3.ZERO, Vector3.UP)


# Dragging functionality of the polygon points
func _input(event):
	var mouse_pos = viewport.get_viewport().get_mouse_position()
	mouse_pos.y = viewport.get_viewport().size.y - mouse_pos.y
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
		var projected_mouse = camera.project_ray_origin(mouse_pos)
		var from = camera.to_local(projected_mouse)
		var to = from + camera.project_local_ray_normal(mouse_pos) * 100
		cursor.set_translation(from)
		cursor.set_cast_to(to)
		if is_dragging and current_point:
			if camera.projection == Camera.PROJECTION_ORTHOGONAL:
				var new_pos = Vector2(projected_mouse.x, projected_mouse.y)
				current_point.set_position(new_pos)
				current_profile.drag()
			else:
				var distance = camera.project_ray_origin(mouse_pos).distance_to(current_point.translation)
				var relative_proj = camera.project_ray_normal(mouse_pos) * distance
				var new_pos = Vector2(relative_proj.x, relative_proj.y)
				current_point.set_position(new_pos)
				current_profile.drag()
	elif event.is_pressed():
		if event.button_index == BUTTON_WHEEL_UP:
			pass
		if event.button_index == BUTTON_WHEEL_DOWN:
			pass


func is_event_inside_control(event: InputEvent, control: Control):
	var window_bounds_y = control.rect_global_position.y + control.rect_size.y 
	var window_bounds_x = control.rect_global_position.x + control.rect_size.x 
	if window_bounds_y > event.position.y and window_bounds_x > event.position.x:
		return true
	else:
		return false
