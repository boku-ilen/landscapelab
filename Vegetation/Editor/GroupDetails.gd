extends VSplitContainer


var current_group


func _ready():
	$GroupAttributes/Attributes/GroundTexture/TextureOptionButton.connect("new_texture_selected",Callable(self,"_set_new_ground_texture"))
	$GroupAttributes/Attributes/FadeTexture/TextureOptionButton.connect("new_texture_selected",Callable(self,"_set_new_fade_texture"))


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
	
	# Select the group's textures in the dropdowns
	$GroupAttributes/Attributes/GroundTexture/TextureOptionButton.select_value(group.ground_texture)
	$GroupAttributes/Attributes/FadeTexture/TextureOptionButton.select_value(group.fade_texture)
	
	$GroupAttributes/Attributes/GroupPlantList.update_plants(group)
