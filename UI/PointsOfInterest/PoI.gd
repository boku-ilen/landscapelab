extends ItemList

func _on_ItemList_item_selected(index):
	pass


func _on_ItemList_item_activated(index):
	GlobalSignal.emit_signal("poi_clicked", index)
