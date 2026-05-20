extends VBoxContainer
class_name DrawLayerDropdownMenu

@export var own_panel: PanelContainer

func create_menu(options, on_selected):
	own_panel.visible = true
	if len(get_children()) > 0:
		return
	for option in options:
		var entry = DrawLayerDropdownEntry.new(option, func(): on_selected.call(option))
		add_child(entry)

func destroy_menu():
	for child in get_children():
		child.queue_free()
	own_panel.visible = false
