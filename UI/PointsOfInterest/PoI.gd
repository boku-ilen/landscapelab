extends ItemList

func _item_activated(index):
	GlobalSignal.emit_signal("poi_clicked", index)