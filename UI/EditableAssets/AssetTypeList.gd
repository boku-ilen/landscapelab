extends ItemList

func _item_activated(index):
	GlobalSignal.emit_signal("selected_asset_type", index)