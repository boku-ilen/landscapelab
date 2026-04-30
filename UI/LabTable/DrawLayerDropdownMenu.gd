extends VBoxContainer
class_name DrawLayerDropdownMenu

#func _init() -> void:
	#visibility_changed.connect(destroy_menu)

func create_menu(options, on_selected):
	if len(get_children()) > 0:
		return
	for option in options:
		var entry = DrawLayerDropdownEntry.new(option, func(): on_selected.call(option))
		add_child(entry)

func destroy_menu():
	for child in get_children():
		child.queue_free()
