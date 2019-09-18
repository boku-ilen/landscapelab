extends ItemList

# Emit the index of the wanted item
func _on_ItemList_item_activated(index):
	GlobalSignal.emit_signal("changed_item_to_spawn", index)
