extends Node

# A variable to store the DSCN_IO node.
var DSCN_IO = null;

# The path to the node we want to use to either import/export a DSCN file.
export (NodePath) var path_to_node;
# The mode for this node. Right now you can either import or export DSCN files.
export (int, "IMPORT", "EXPORT") var mode = 0;
# The filepath of/for the DSCN file. This is a multiline export
# so we can easily see the path in the editor.
export (String, MULTILINE) var filepath;
# A boolean for whether this node should try and import/export a DSCN file in
# it's _ready function.
export (bool) var execute_in_ready = false;


func _ready():
	
	# Load the DSCN node, make a instance of it, and then make it a child of this node.
	var DSCN_IO_INSTANCE = preload("res://addons/dscn_io/DSCN_IO.tscn");
	DSCN_IO = DSCN_IO_INSTANCE.instance();
	add_child(DSCN_IO);
	
	# If we need to execute in _ready, then figure out
	# which function we need to call and then call it.
	if (execute_in_ready == true):
		if (mode == 0):
			import_dscn();
		elif (mode == 1):
			export_dscn();


func export_dscn():
	
	# Get the selected node, and the root node the DSCN_Runtime_Node is in.
	var selected_node = get_node(path_to_node);
	var scene_root = get_tree().root.get_child(get_tree().root.get_child_count()-1);
	
	# Export the DSCN file, passing in the filepath, the selected node, and
	# the root of the scene the DSCN_Runtime node is in.
	var result = DSCN_IO.export_dscn(filepath, selected_node, scene_root);
	
	# Based on the result of the export, print to the console saying what happened.
	if (result == DSCN_IO.DSCN_IO_STATUS.EXPORT_SUCCESS):
		print ("DSCN file exported successfully to file: " + filepath);
	else:
		var reason = "";
		
		if (result == DSCN_IO.DSCN_IO_STATUS.IMPORT_SUCCESS):
			reason = "Programmer is a clutz and sent import success instead of export success!";
		elif (result == DSCN_IO.DSCN_IO_STATUS.NO_NODE_SELECTED):
			reason = "No node was selected!";
		elif (result == DSCN_IO.DSCN_IO_STATUS.SELECTED_NODE_NOT_FOUND):
			reason = "The selected node was not found in the currently open scene!";
		elif (result == DSCN_IO.DSCN_IO_STATUS.FILE_NOT_FOUND):
			reason = "Could not find file!";
		
		print ("DSCN file export failed. Reason: " + reason);


func import_dscn():
	
	# Get the selected node, and the root node the DSCN_Runtime_Node is in.
	var selected_node = get_node(path_to_node);
	var scene_root = get_tree().root.get_child(get_tree().root.get_child_count()-1);
	
	# Import the DSCN file, passing in the filepath, the selected node, and
	# the root of the scene the DSCN_Runtime node is in.
	var result = DSCN_IO.import_dscn(filepath, selected_node, scene_root);
	
	# Based on the result of the import, print to the console saying what happened.
	if (result == DSCN_IO.DSCN_IO_STATUS.IMPORT_SUCCESS):
		print ("DSCN file imported successfully from file: " + filepath);
	else:
		var reason = "";
		
		if (result == DSCN_IO.DSCN_IO_STATUS.EXPORT_SUCCESS):
			reason = "Programmer is a clutz and sent export success instead of import success!";
		elif (result == DSCN_IO.DSCN_IO_STATUS.NO_NODE_SELECTED):
			reason = "No node was selected!";
		elif (result == DSCN_IO.DSCN_IO_STATUS.SELECTED_NODE_NOT_FOUND):
			reason = "The selected node was not found in the currently open scene!";
		elif (result == DSCN_IO.DSCN_IO_STATUS.FILE_NOT_FOUND):
			reason = "Could not find file!";
		
		print ("DSCN file export failed. Reason: " + reason);

