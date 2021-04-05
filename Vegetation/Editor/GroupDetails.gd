extends VSplitContainer


var current_group


func _ready():
	$GroupAttributes/Attributes/GroundTexture/TextureOptionButton.connect("new_texture_selected", self, "_set_new_ground_texture")
	$GroupAttributes/Attributes/FadeTexture/TextureOptionButton.connect("new_texture_selected", self, "_set_new_fade_texture")


func _set_new_ground_texture(new_ground_texture):
	if current_group:
		current_group.ground_texture = new_ground_texture


func _set_new_fade_texture(new_fade_texture):
	if current_group:
		current_group.fade_texture = new_fade_texture


func set_group(group):
	current_group = group
	
	$GroupAttributes/Attributes/ID/Label.text = str(group.id)
	$GroupAttributes/Attributes/Name/LineEdit.text = group.name_en
	
	# Select the group's texture in the dropdown -- subtract 1 because the IDs start at 1
	$GroupAttributes/Attributes/GroundTexture/TextureOptionButton.select(group.ground_texture.id - 1)
	
	$GroupAttributes/Attributes/GroupPlantList.update_plants(group)
