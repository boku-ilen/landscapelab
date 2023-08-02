extends OptionButton


@export var vegetation_field_to_access: String

signal new_texture_selected(texture_name)


func _ready():
	if not vegetation_field_to_access in Vegetation:
		logger.error("Invalid vegetation field %s in dropdown %s!"
				% [vegetation_field_to_access, name])
		return
	
	var item_id = 0
	
	# Add a first item for null values
	add_item("None")
	item_id += 1
	
	for texture in Vegetation.get(vegetation_field_to_access).values():
		add_item(texture.texture_name)
		set_item_metadata(item_id, texture)
		
		item_id += 1
	
	connect("item_selected",Callable(self,"_on_item_selected"))


func _on_item_selected(item_id):
	emit_signal("new_texture_selected", get_item_metadata(item_id))


# Selects the (first) item which has the given value as its metadata.
# O(N) at worst. This is done because the IDs may not match up with the item indices.
func select_value(value):
	# If the given value is null, select the item representing null
	if not value:
		select(0)
		return
	
	for item_id in range(0, get_item_count()):
		if get_item_metadata(item_id) == value:
			select(item_id)
			return
	
	# If nothing was found, select the item representing null as well
	select(0)
