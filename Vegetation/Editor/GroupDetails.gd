extends VSplitContainer


var current_group


func _ready():
	$GroupAttributes/Attributes/Texture/TextureSelectButton/TextureFileDialog.connect("new_texture_selected", self, "_set_new_ground_texture")


func _set_new_ground_texture(new_path):
	current_group.ground_texture_path = new_path
	print(current_group.name, current_group.ground_texture_path)


func set_group(group):
	current_group = group
	
	$GroupAttributes/Attributes/ID/Label.text = str(group.id)
	$GroupAttributes/Attributes/Name/LineEdit.text = group.name
	
	$GroupAttributes/Attributes/GroupPlantList.update_plants(group)
