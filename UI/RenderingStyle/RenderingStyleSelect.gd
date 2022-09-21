extends ItemList


func _ready() -> void:
	# Add all styles from the RenderStyle list.
	# Because the order of adding is the same as the order in RenderStyle.styles,
	#  these item IDs are the same as the IDs in the RenderStyle list.
	for style in RenderStyle.styles:
		add_item(style.name)
	
	connect("item_activated",Callable(self,"_on_item_activated"))


func _on_item_activated(id: int):
	RenderStyle.emit_signal("change_style", RenderStyle.styles[id])
