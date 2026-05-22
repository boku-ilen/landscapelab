@tool
extends EditorPlugin

var dock: EditorDock

func _enable_plugin() -> void:
	# Add autoloads here.
	pass


func _disable_plugin() -> void:
	# Remove autoloads here.
	pass


func _enter_tree() -> void:
	var dock_scene = preload("res://addons/building_graph_editor/Editor/BuildingGraphEditorDock.tscn").instantiate()
	dock = EditorDock.new()
	dock.add_child(dock_scene)
	dock.title = "Building Graph Editing"
	dock.default_slot = EditorDock.DOCK_SLOT_BOTTOM
	dock.available_layouts = EditorDock.DOCK_LAYOUT_HORIZONTAL | EditorDock.DOCK_LAYOUT_FLOATING
	add_dock(dock)


func _exit_tree() -> void:
	remove_dock(dock)
	dock.queue_free()
