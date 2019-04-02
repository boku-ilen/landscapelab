tool
extends Control


var editor_interface = null;
var DSCN_IO = null;

var DSCN_notice_popup = null;


# ======== EXPORTER VARIABLES ==============
var export_get_selected_button = null;
var export_selected_node_label = null;
var export_button = null;

var export_save_file_dialog = null;

var export_selected_node = null;
# ===========================================


# ======== IMPORTER VARIABLES ==============
var import_get_selected_button = null;
var import_selected_node_label = null;
var import_button = null;

var import_load_file_dialog = null;

var import_selected_node = null;
# ===========================================


func _ready():
	
	DSCN_IO = get_node("DSCN_IO");
	DSCN_notice_popup = get_node("NoticeDialog");
	
	# ======== EXPORTER ==============
	export_get_selected_button = get_node("ScrollContainer/VBoxContainer/Export_Options/VBoxContainer/Button_Get_Selected");
	export_selected_node_label = get_node("ScrollContainer/VBoxContainer/Export_Options/VBoxContainer/Label_Selected_Node");
	export_button = get_node("ScrollContainer/VBoxContainer/Export_Options/VBoxContainer/Button_Export");
	
	export_save_file_dialog = get_node("Save_FileDialog");
	export_save_file_dialog.connect("file_selected", self, "export_dscn");
	
	export_get_selected_button.connect("pressed", self, "export_get_select_nodepath");
	export_button.connect("pressed", self, "export_open_popup");
	
	export_button.disabled = true;
	# ================================
	
	
	# ======== IMPORTER ==============
	import_get_selected_button = get_node("ScrollContainer/VBoxContainer/Import_Options/VBoxContainer/Button_Get_Selected");
	import_selected_node_label = get_node("ScrollContainer/VBoxContainer/Import_Options/VBoxContainer/Label_Selected_Node");
	import_button = get_node("ScrollContainer/VBoxContainer/Import_Options/VBoxContainer/Button_Import");
	
	import_load_file_dialog = get_node("Load_FileDialog");
	import_load_file_dialog.connect("file_selected", self, "import_dscn");
	
	import_get_selected_button.connect("pressed", self, "import_get_select_nodepath");
	import_button.connect("pressed", self, "import_open_popup");
	
	import_button.disabled = true;
	# ================================


func show_popup(status_text):
	DSCN_notice_popup.get_node("Status_Label").text = status_text;
	DSCN_notice_popup.popup_centered();


# ======== EXPORTER FUNCTIONS ==============

func export_get_select_nodepath():
	
	if (editor_interface == null):
		print ("Error: No editor interface found!");
		return;
	
	var selection = editor_interface.get_selection();
	var selected_nodes = selection.get_selected_nodes();
	if (selected_nodes.size() > 0):
		export_selected_node = selected_nodes[0];
		
		export_selected_node_label.text = "Selected Node: " + export_selected_node.name;
		
		export_button.disabled = false;
	
	else:
		export_selected_node = null;
		export_selected_node_label.text = "Selected Node: NONE";
		export_button.disabled = true;


func export_open_popup():
	export_save_file_dialog.popup_centered();


func export_dscn(filepath):
	
	var result = DSCN_IO.export_dscn(filepath, export_selected_node, editor_interface.get_edited_scene_root());
	
	if (result == DSCN_IO.DSCN_IO_STATUS.EXPORT_SUCCESS):
		show_popup("DSCN file exported successfully to file\n" + filepath);
	else:
		var reason = "";
		
		if (result == DSCN_IO.DSCN_IO_STATUS.IMPORT_SUCCESS):
			reason = "TwistedTwigleg is a clutz and sent import success instead of export success!";
		elif (result == DSCN_IO.DSCN_IO_STATUS.NO_NODE_SELECTED):
			reason = "No node was selected!";
		elif (result == DSCN_IO.DSCN_IO_STATUS.SELECTED_NODE_NOT_FOUND):
			reason = "The selected node was not found in the currently open scene!";
		elif (result == DSCN_IO.DSCN_IO_STATUS.FILE_NOT_FOUND):
			reason = "Could not find file!";
		
		show_popup("DSCN file export failed. Reason:\n" + reason);

# ==========================================


# ======== IMPORTER FUNCTIONS ==============

func import_get_select_nodepath():
	
	if (editor_interface == null):
		print ("Error: No editor interface found!");
		return;
	
	var selection = editor_interface.get_selection();
	var selected_nodes = selection.get_selected_nodes();
	if (selected_nodes.size() > 0):
		import_selected_node = selected_nodes[0];
		
		import_selected_node_label.text = "Selected Node: " + import_selected_node.name;
		
		import_button.disabled = false;
	
	else:
		import_selected_node = null;
		import_selected_node_label.text = "Selected Node: NONE";
		import_button.disabled = true;


func import_open_popup():
	import_load_file_dialog.popup_centered();


func import_dscn(filepath):
	
	var result = DSCN_IO.import_dscn(filepath, import_selected_node, editor_interface.get_edited_scene_root());
	
	if (result == DSCN_IO.DSCN_IO_STATUS.IMPORT_SUCCESS):
		show_popup("DSCN file imported successfully from file\n" + filepath);
	else:
		var reason = "";
		
		if (result == DSCN_IO.DSCN_IO_STATUS.EXPORT_SUCCESS):
			reason = "TwistedTwigleg is a clutz and sent export success instead of import success!";
		elif (result == DSCN_IO.DSCN_IO_STATUS.NO_NODE_SELECTED):
			reason = "No node was selected!";
		elif (result == DSCN_IO.DSCN_IO_STATUS.SELECTED_NODE_NOT_FOUND):
			reason = "The selected node was not found in the currently open scene!";
		elif (result == DSCN_IO.DSCN_IO_STATUS.FILE_NOT_FOUND):
			reason = "Could not find file!";
		
		show_popup("DSCN file export failed. Reason:\n" + reason);

# ==========================================


