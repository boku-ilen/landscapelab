extends VBoxContainer


var current_profile :
	get:
		return current_profile # TODOConverter40 Non existent get function 
	set(mod_value):
		mod_value  # TODOConverter40 Copy here content of set_current_profile


func set_current_profile(profile):
	current_profile = profile


func _ready():
	$RemoveProfileButton.connect("pressed",Callable(self,"_remove_profile"))
	$FileChooser/AddText.connect("pressed",Callable(self,"_add_texture"))
	$StructuredTextureChooser/AddMaterial.connect("pressed",Callable(self,"_add_structured_texture"))


func _add_profile(profile, path, drag_handler):
	var new_prof = profile.instantiate()
	path.add_child(new_prof)
	new_prof.path_node = "../"
	
	for poly_point in new_prof.get_children():
		drag_handler.dragables[poly_point.name] = drag_handler.DragablePoint.new(poly_point, new_prof)


func _remove_profile():
	if current_profile:
		current_profile.queue_free()
		current_profile = null


func _add_texture():
	var texture = load($FileChooser/FileName.text)
	var mat = StandardMaterial3D.new()
	mat.albedo_texture = texture
	current_profile.material = mat


func _add_structured_texture():
	var mat = StructuredTexture.get_material($StructuredTextureChooser/DirName.text)
	if mat:
		current_profile.material = mat
