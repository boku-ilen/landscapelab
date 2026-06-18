@tool
extends EditorPlugin

var building_dock: EditorDock
var selector_dock: EditorDock

func _enable_plugin() -> void:
	# Add autoloads here.
	pass


func _disable_plugin() -> void:
	# Remove autoloads here.
	pass


func _enter_tree() -> void:
	var building_dock_scene = preload("res://addons/building_graph_editor/Editor/BuildingGraphEditorDock.tscn").instantiate()
	building_dock = EditorDock.new()
	building_dock.add_child(building_dock_scene)
	building_dock.title = "Building Graph Editing"
	building_dock.default_slot = EditorDock.DOCK_SLOT_BOTTOM
	building_dock.available_layouts = EditorDock.DOCK_LAYOUT_HORIZONTAL | EditorDock.DOCK_LAYOUT_FLOATING
	add_dock(building_dock)
	
	var selector_dock_scene = preload("res://addons/building_graph_editor/Editor/SelectorGraphEditorDock.tscn").instantiate()
	selector_dock = EditorDock.new()
	selector_dock.add_child(selector_dock_scene)
	selector_dock.title = "Building Selector Graph"
	selector_dock.default_slot =  EditorDock.DOCK_SLOT_BOTTOM
	selector_dock.available_layouts = EditorDock.DOCK_LAYOUT_HORIZONTAL | EditorDock.DOCK_LAYOUT_FLOATING
	add_dock(selector_dock)

func _exit_tree() -> void:
	remove_dock(building_dock)
	remove_dock(selector_dock)
	building_dock.queue_free()
	selector_dock.queue_free()
