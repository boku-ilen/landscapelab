extends ItemList


func ready():
	connect("item_activated", self, "_on_item_activated")


# Emit the index of the wanted item
func _on_item_activated(index):
	#GlobalSignal.emit_signal("changed_item_to_spawn", index)
	
	var item_id = get_item_metadata(index)
	GlobalSignal.emit_signal("changed_asset_id", int(item_id))
