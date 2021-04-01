extends OptionButton


export(String) var vegetation_field_to_access

signal new_texture_selected(texture_name)


func _ready():
	if not vegetation_field_to_access in Vegetation:
		logger.error("Invalid vegetation field %s in dropdown %s!"
				% [vegetation_field_to_access, name])
		return
	
	var item_id = 0
	for texture in Vegetation.get(vegetation_field_to_access).values():
		add_item(texture.texture_name)
		set_item_metadata(item_id, texture)
		
		item_id += 1
	
	connect("item_selected", self, "_on_item_selected")


func _on_item_selected(item_id):
	emit_signal("new_texture_selected", get_item_metadata(item_id))
