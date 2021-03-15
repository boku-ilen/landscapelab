extends VSplitContainer


var current_group


func _ready():
	$GroupAttributes/Attributes/Texture/TextureSelectButton/TextureFileDialog.connect("new_texture_selected", self, "_set_new_ground_texture")


func _set_new_ground_texture(new_path):
	if current_group:
		current_group.ground_texture_folder = new_path


func set_group(group):
	current_group = group
	
	$GroupAttributes/Attributes/ID/Label.text = str(group.id)
	$GroupAttributes/Attributes/Name/LineEdit.text = group.name_en
	
	$GroupAttributes/Attributes/GroupPlantList.update_plants(group)
