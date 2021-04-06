extends VBoxContainer


var current_profile setget set_current_profile


func set_current_profile(profile):
	current_profile = profile


func _ready():
	$RemoveProfileButton.connect("pressed", self, "_remove_profile")
	$FileChooser/AddText.connect("pressed", self, "_add_texture")
	$StructuredTextureChooser/AddMaterial.connect("pressed", self, "_add_structured_texture")


func _add_profile(profile, path):
	var new_prof = profile.instance()
	path.add_child(new_prof)
	new_prof.path_node = "../"


func _remove_profile():
	if current_profile:
		current_profile.queue_free()
		current_profile = null


func _add_texture():
	var texture = load($FileChooser/FileName.text)
	var mat = SpatialMaterial.new()
	mat.albedo_texture = texture
	current_profile.material = mat


func _add_structured_texture():
	var mat = StructuredTexture.get_material($StructuredTextureChooser/DirName.text)
	if mat:
		current_profile.material = mat
