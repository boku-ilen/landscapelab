extends ItemList

func _item_activated(index):
	GlobalSignal.emit_signal("changed_item_to_spawn", index)