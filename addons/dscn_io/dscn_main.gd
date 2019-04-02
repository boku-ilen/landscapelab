tool
extends EditorPlugin

var DSCN_Dock;

func _enter_tree():
	DSCN_Dock = preload("res://addons/dscn_io/DSCN Dock.tscn").instance();
	
	# Add custom dock(s)
	add_control_to_dock(DOCK_SLOT_LEFT_UR, DSCN_Dock);
	# Setup custom dock(s)
	DSCN_Dock.editor_interface = get_editor_interface();
	# Add custom node(s)
	add_custom_type("DSCN_Runtime_Node", "Node", preload("DSCN_Runtime_Node.gd"), preload("DSCN_Node_Icon.png"));
	

func _exit_tree():
	# Remove custom dock(s)
	remove_control_from_docks(DSCN_Dock);
	# Free custom dock(s) memory
	DSCN_Dock.free();
	# Remove custom node(s)
	remove_custom_type("DSCN_Runtime_Node");
