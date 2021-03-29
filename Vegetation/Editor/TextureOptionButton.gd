extends OptionButton


signal new_texture_selected(texture_name)


func _ready():
	var item_id = 0
	for texture in Vegetation.ground_textures.values():
		add_item(texture.texture_name)
		set_item_metadata(item_id, texture)
		
		item_id += 1
	
	connect("item_selected", self, "_on_item_selected")


func _on_item_selected(item_id):
	emit_signal("new_texture_selected", get_item_metadata(item_id))
