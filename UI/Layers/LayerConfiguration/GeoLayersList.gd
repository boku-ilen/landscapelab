extends ItemList

#
# Display of all geolayers and handling for z-index of geo-layers in the 2D space.
#


signal z_index_changed(item_array)


func get_items():
	var items = []
	for idx in range(item_count):
		items.append({ "name": get_item_text(idx), "z_idx": item_count - idx })
	return items


func _can_drop_data(_at_position, data):
	if not "geolayer" in data: return
	return data.geolayer is GeoFeatureLayer or data.geolayer is GeoRasterLayer


func _drop_data(at_position, data):
	var item_idx = get_item_at_position(at_position)
	move_item(data.idx, item_idx)
	z_index_changed.emit(get_items())


func _get_drag_data(at_position):
	var item_idx = get_item_at_position(at_position)
	var item_metadata = get_item_metadata(item_idx)
	var item_name = get_item_text(item_idx)
	
	var data = {"idx": item_idx, "geolayer": item_metadata}
	var preview = Label.new()
	preview.text = item_name
	set_drag_preview(preview)
	
	return data
