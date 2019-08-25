extends ItemList

func _on_ItemList_item_selected(index):
	GlobalSignal.emit_signal("poi_clicked", index)
