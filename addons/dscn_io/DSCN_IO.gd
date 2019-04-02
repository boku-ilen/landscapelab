tool
extends Node

# TODO: rewrite this!
# DSCN FILE FORMAT (0.1.0):
	#	Number of nodes stored in Node list: 1 (or however many nodes are stored)
	#	Number of resources stored in Resource list: 1 (or however many resources are stored)
	#	JSON NodeTree: JSON Dictionary built using the node names as the key, and the children
	#					nodes as values. Leaf nodes only have a single value, called DSCN_Resources
	#					which holds all of the resources the leaf node needs.
	#	Metadata : (Nothing for now, but saving this in case!)
	#	Export Version : 0.1.0
	#	Node list : all nodes are dumped using "file.store_var(nodes));"
	#	Resource list : each node is dumped using "file.store_var(resource);"


# All of the results that can be returned when trying to export/import
# a DSCN file.
enum DSCN_IO_STATUS {
	IMPORT_SUCCESS,
	EXPORT_SUCCESS,
	NO_NODE_SELECTED,
	SELECTED_NODE_NOT_FOUND,
	FILE_NOT_FOUND,
}

# A variable to hold the DSCN_resource_manager script.
var DSCN_resource_manager = null;


func _ready():
	# We are going to assume that every node that has DSCN_IO has a child
	# called DSCN_Resource_Manager that holds the DSCN_Resource_Manager.gd script.
	DSCN_resource_manager = get_node("DSCN_Resource_Manager");


# ======== EXPORTER FUNCTIONS ==============


# Will export a DSCN file.
#
# Needs the following arguments:
#	filepath: The file path pointing to where you want to save the DSCN file.
#				(This can be anywhere on the file system!)
#	selected_node: The node you want to save
#				(This will save the children of the selected node as well!)
#	scene_root: The root of the scene selected_node is in.
#
# This function needs the scene root to ensure selected_node is in the
# currently open scene.
# (And for argument completeness with the import_dscn function)
#
# Will return one of the values in DSCN_IO_STATUS.
func export_dscn(filepath, selected_node, scene_root):
	
	# Make sure a node is selected. Return a error if it does not.
	if (selected_node == null):
		return DSCN_IO_STATUS.NO_NODE_SELECTED;
	
	# Make sure the node exists in the passed in scene_root.
	var path_in_open_scene = scene_root.get_path_to(selected_node);
	if (path_in_open_scene != null):
		
		# Double check to make sure the node exists.
		# Return a error if it does not.
		if (scene_root.has_node(path_in_open_scene) == false):
			return DSCN_IO_STATUS.SELECTED_NODE_NOT_FOUND;
		
		# Make a new file so we can write the data to it.
		# open the file in WRITE mode at the passed in filepath.
		var export_file = File.new();
		export_file.open(filepath, export_file.WRITE);
		
		# Save all of the DSCN data into the file.
		_save_dscn(scene_root.get_node(path_in_open_scene), export_file);
		
		# Close the file.
		export_file.close();
		
		# If we got this far, then the DSCN file has successfully been exported!
		return DSCN_IO_STATUS.EXPORT_SUCCESS;
	
	# If the node does not exist in the scene, then we need to return a error.
	else:
		return DSCN_IO_STATUS.SELECTED_NODE_NOT_FOUND;


# This function will save all of the DSCN data into the passed in file.
#
# Needs the following arguments:
#	node: The node you want to save to into the DSCN file.
#	file: The file the DSCN data needs to be saved into.
func _save_dscn(node, file):
	
	# Duplicate the node (and all it's children).
	# Make sure we are also duplicating scripts, groups, and signals!
	var duplicate_node = node.duplicate(DUPLICATE_SCRIPTS + DUPLICATE_GROUPS + DUPLICATE_SIGNALS);
	
	# Make a JSON NodeTree, make the resource list, and make the node list, all using
	# the add_node_to_json_node_tree function
	
	# Make the JSON node tree. This is where we will be storing any/all information
	# about the nodes that we will need to convert/parse the DSCN file back into
	# a scene.
	var JSON_node_tree = {};
	# Make the Resource list. This is a list where we will store all of the resources
	# needed in the scene. We will access resources in this list based on the index
	# they are assigned with when added to the list.
	var resource_list = [];
	# Make the Node list. This is a list where all of the nodes (and children nodes)
	# needed in the scene will be stored. Like with Resource List, we will access
	# nodes in the list using the index they are assigned with when added to the list.
	var node_list = [];
	
	# A temporary dictionary for checking for resources.
	# We need this because some resources return new references when we get the data we
	# need out of them, and if we do not check the actual object (not the data), we
	# would in up storing duplicates of each resource used (which increases file size).
	#
	# This is primarily used for images, because get_data returns a new reference every
	# time it is used.
	var resource_check_dict = {};
	
	# Start adding the node data into JSON_node_tree, node_list, resource_list,
	# and resource_check_dict.
	#
	# This is a recursive function that will add the node data for all of the
	# children of the passed in node until there are no children left.
	_add_node_data_to_dscn(duplicate_node, JSON_node_tree, node_list, resource_list, resource_check_dict)
	
	# Add all of the signals for all of the nodes
	for node in node_list:
		_add_node_signals(node, node_list, JSON_node_tree);
	
	# Store the number of nodes in node_list.
	file.store_line(str(node_list.size()));
	# Store the number of resources in resource_list.
	file.store_line(str(resource_list.size()));
	
	# Store the JSON tree.
	file.store_line(to_json(JSON_node_tree));
	
	# Store Metadata and Export version
	file.store_line("NULL");
	file.store_line("0.1.0");
	
	# Store nodes
	for node_to_store in node_list:
		file.store_var(node_to_store);
	
	# Store resources
	for resource_to_store in resource_list:
		file.store_var(resource_to_store);
	
	# Print success!
	print ("**** DSCN_IO ****");
	print ("Saved the following node tree: ")
	print (duplicate_node.print_tree_pretty());
	print ("*****************");


# This function will add all of the data into json_tree, node_list, resource_list
# and resource_check_dict that we need to load the nodes out of DSCN files.
# 
# Needs the following arguments:
#	node: The node whose data is currently being saved.
#	json_tree: The JSON node tree dictionary where we can store data needed
#				load the nodes we are saving.
#	node_list: A list holding all of the nodes in the scene we want to save.
#				This function will populate this list with node and it's children!
#	resource_list: A list holding all of the resources in the scene we need to save.
#				This function will populate this list with the resources node needs!
#	resource_check_dict: A dictionary holding resources we may need to check against
#				To avoid storing duplicate data. This function may populate this dictionary.
func _add_node_data_to_dscn(node, json_tree, node_list, resource_list, resource_check_dict):
	
	# Add the node to the node_list and get it's position in node_list.
	node_list.append(node);
	var node_position_in_list = node_list.size()-1
	
	# Get all of the resources this node is dependent on and store them into
	# node_dependency_dict.
	var node_dependency_dict = {}
	DSCN_resource_manager.add_node_resources_to_list_and_dict(node, node_dependency_dict, resource_list, resource_check_dict);
	
	# Tell all of the children nodes to save their data.
	var child_nodes_for_node = node.get_children();
	for child_node in child_nodes_for_node:
		_add_node_data_to_dscn(child_node, json_tree, node_list, resource_list, resource_check_dict);
	
	# Get the positions of the children nodes in node_list so we can later
	# reconstruct the node tree when loading DSCN files.
	var child_ids = [];
	for child in child_nodes_for_node:
		child_ids.append(node_list.find(child));
	
	# Save the data needed to import this node into json_tree.
	json_tree[node_position_in_list] = {
		"DSCN_Dependencies":node_dependency_dict,
		"DSCN_Children":child_ids,
		"DSCN_Node_Name":node.name,
	};
	

# This function will add all of the signals from the passed in node into json_tree.
#
# Needs the following arguments:
#	node: The node whose data is currently being saved.
#	node_list: A list holding all of the nodes in the scene we want to save.
#	json_tree: The JSON node tree dictionary where we can store data needed
#				load the nodes we are saving.
func _add_node_signals(node, node_list, json_tree):
	
	# Figure out where this node is positioned in node_list.
	var position_of_node_in_list = node_list.find(node);
	
	# Get all of the signals this node COULD have connected.
	# Make sure this node has at least one (possibly) connected signal.
	var signal_list = node.get_signal_list();
	if (signal_list.size() > 0):
		
		# Add the amount of signals this node has to json_tree.
		json_tree[position_of_node_in_list]["DSCN_Signal_Count"] = signal_list.size();
		
		# Go through each signal in signal list...
		for i in range(0, signal_list.size()):
			
			# Get the signal data and store it in signal_item.
			var signal_item = signal_list[i];
			
			# Get all of the connections this signal may have.
			# Make sure this signal has at least one connection.
			var signal_connections = node.get_signal_connection_list(signal_item["name"])
			if (signal_connections.size() > 0):
				
				# Add the amount of connections this one signal has to json_tree.
				json_tree[position_of_node_in_list]["DSCN_Connection_Count_" + str(i)] = signal_connections.size();
				
				# Go through each connection in signal_connections...
				for j in range(0, signal_connections.size()):
					
					# Get the connection data.
					var signal_connection = signal_connections[j];
					# Find the source node and target node in node_list.
					var source_position = node_list.find(signal_connection["source"])
					var target_position = node_list.find(signal_connection["target"]);
					
					# Make sure node_list contains both the source and the target.
					if (source_position != -1 and target_position != -1):
						# Change the source and target variables in the signal_connection
						# dictionary to store the position of the source and target nodes
						# in node_list.
						signal_connection["source"] = source_position;
						signal_connection["target"] = target_position;
						
						# Save the signal connection in json_tree.
						json_tree[position_of_node_in_list]["DSCN_Signal_" + str(j)] = signal_connection;
				


# ==========================================


# ======== IMPORTER FUNCTIONS ==============


# Will import a DSCN file.
#
# Needs the following arguments:
#	filepath: The file path pointing to where the DSCN file you want to load is.
#					(This can be anywhere on the the file system!)
#	selected_node: The node that will have the nodes in the DSCN file as it's children.
#					(Will include the DSCN file's children!)
#	scene_root: The root of the scene selected_node is in.
#
#
# Will return one of the values in DSCN_IO_STATUS depending on the import status.
func import_dscn(filepath, selected_node, scene_root):
	
	# Make sure a node is selected. Return a error if it does not.
	if (selected_node == null):
		return DSCN_IO_STATUS.NO_NODE_SELECTED;
	
	# Make sure the node exists in the passed in scene_root.
	var path_in_open_scene = scene_root.get_path_to(selected_node);
	if (path_in_open_scene != null):
		
		# Double check to make sure the node exists.
		# Return a error if it does not.
		if (scene_root.has_node(path_in_open_scene) == false):
			return DSCN_IO_STATUS.SELECTED_NODE_NOT_FOUND;
		
		# Make a new file so we can read the data to it.
		# Make sure there is a file at the passed in filepath...
		var file = File.new();
		if (file.file_exists(filepath) == false):
			return DSCN_IO_STATUS.FILE_NOT_FOUND;
		
		# Open the file in READ mode.
		file.open(filepath, file.READ);
		
		# Make a new variable to store the root node of the loaded DSCN
		# scene file.
		var loaded_scene = null;
		
		# Load all of the nodes in the DSCN file.
		loaded_scene = _load_dscn(file);
		
		# Add the loaded root node (and it's children) to the selected node.
		selected_node.add_child(loaded_scene);
		
		# Set all of the node owners to scene_root so they will be saved
		# properly with scene_root.
		_set_node_owners(loaded_scene, scene_root);
		
		# Close the file.
		file.close();
		
		# Return success
		return DSCN_IO_STATUS.IMPORT_SUCCESS;


# This function will load all of the DSCN data from the passed in file.
#
# Needs the following arguments:
#	file: The file the DSCN data is saved in.
func _load_dscn(file):
	
	# Get the number of nodes in the saved nodes_list in the DSCN file.
	var nodes_in_list = int(file.get_line());
	# Get the number of resources in the saved resource_list in the DSCN file.
	var resources_in_list = int(file.get_line());
	# Get the JSON node tree holding all of the data we will need to parse
	# the nodes from the saved DSCN file.
	var file_JSON_node_tree = parse_json(file.get_line());
	# Get the meta data from the saved DSCN file (as of version 0.1.0, this stores nothing)
	var file_meta_data = file.get_line();
	# Get the version of the DSCN file.
	var file_export_version = file.get_line();
	
	# Make sure the version of the DSCN file is the same version as this plugin.
	if (file_export_version != "0.1.0"):
		print ("ERROR: Cannot import DSCN file with version: ", file_export_version);
		print ("Can only import DSCN files with version: 0.1.0");
		return null;
	
	# Make a empty node list and resource list.
	var node_list = [];
	var resource_list = [];
	
	# Get all of the nodes in the saved DSCN file (using nodes_in_list)
	# and place those nodes in node_list.
	for i in range(0, nodes_in_list):
		var stored_node = file.get_var();
		node_list.append(stored_node);
	
	# Get all of the resources in the saved DSCN file (using resources_in_list)
	# and place those resources in resource_list.
	for i in range(0, resources_in_list):
		var stored_resource = file.get_var();
		resource_list.append(stored_resource);
	
	# Add resources to all of the nodes in node_list
	for i in range(0, node_list.size()):
		# Get the node and assign it's name to the name saved in the JSON_node_tree.
		var node = node_list[i];
		node.name = file_JSON_node_tree[str(i)]["DSCN_Node_Name"];
		
		# Tell DSCN_resource_manager to load the resources for this node from resource_list.
		#
		# We need to pass in the data in node, file_JSON_node_tree, and resource_list so
		# the resource manager can assign the proper resources from resource_list.
		DSCN_resource_manager.load_node_resources_from_list(node, file_JSON_node_tree[str(i)], resource_list);
		
	
	# Load all of the signals for all of the nodes in node_list
	for node in node_list:
		_load_node_signals(node, node_list, file_JSON_node_tree);
	
	
	# Rebuild the node tree, and then get and assign the root of the loaded DSCN file
	# to a new variable called final_scene.
	var final_scene = _rebuild_node_tree(node_list[0], file_JSON_node_tree, node_list);
	
	# (Optional) print what we imported.
	print ("**** DSCN_IO ****");
	print ("Added the following node tree: ")
	print (final_scene.print_tree_pretty());
	print ("*****************");
	
	# Return the root node of the imported DSCN file.
	return final_scene;

# This function will rebuild the node tree saved in the DSCN file
# using the data in json_node_tree.
#
# Needs the following arguments:
#	node : The current node that is having it's children added
#	json_node_tree : The saved json_node_tree from the DSCN file.
#	node_list : A list containing every node in the loaded DSCN file.
func _rebuild_node_tree(node, json_node_tree, node_list):
	
	# Make a empty list of children in this node.
	var node_children = [];
	
	# Find this node's position in node_list.
	var node_position = node_list.find(node);
	
	# If the node was found, then get the children of this node (stored in json_node_tree).
	if (node_position != -1):
		node_children = json_node_tree[str(node_position)]["DSCN_Children"];
	
	# If this node has no children, then return.
	if (node_children.size() <= 0):
		return node;
	
	# If this node has children node(s).
	else:
		# For each child in node_children.
		for child in node_children:
			# Get the child node using the stored position of the child.
			# (which is the data in DSCN_Children)
			var child_node = node_list[child];
			# Add the child node as a child of this node.
			# We are calling _rebuild_node_tree so if the child node has children,
			# then they will be added BEFORE adding this child node as a child of this node.
			#
			# (confusing, no? This is a recursive depth-first function that adds children
			# nodes to the passed in node, going all the way down the scene tree stored
			# in json_node_tree)
			node.add_child(_rebuild_node_tree(child_node, json_node_tree, node_list));
		
		# Return the node, now that it has its children added to it
		return node;


# This node will set the owner of the passed in node to the passed in owner.
# This will also set the owner of all of the children of the passed in node
# to the same owner as the passed in node.
#
# Needs the following arguments:
#	node : The node (and children of this node) whose owner we want to set.
#	owner : The thing we want to be the owner of node.
func _set_node_owners(node, owner):
	# Set the owner of the node to the passed in owner argument.
	node.set_owner(owner);
	
	# Go through the children in this node...
	# (NOTE: this means rebuild_scene_tree has to be called BEFORE _set_node_owners)
	for child in node.get_children():
		# and called _set_node_owners on them as well, passing in the owner
		# of this node.
		_set_node_owners(child, owner);


# This function will load all of the signals from the passed in node from json_tree.
#
# Needs the following arguments:
#	node: The node whose signals we want to load.
#	node_list: A list holding all of the nodes in the loaded DSCN file.
#	json_tree: The JSON node tree dictionary loaded from the DSCN file.
func _load_node_signals(node, node_list, json_tree):
	
	# Find the position of the node in node_list.
	var position_of_node_in_list = node_list.find(node);
	
	# See if the DSCN_Signal_Count key is in the data for this node in json_tree.
	if ((json_tree[str(position_of_node_in_list)]).has("DSCN_Signal_Count") == true):
		
		# If DSCN_Signal_Count is in the data for this node, get it and assign it to signal_count.
		var signal_count = json_tree[str(position_of_node_in_list)]["DSCN_Signal_Count"];
		
		# Go through each of the (potentially saved) signals...
		for i in range(0, signal_count):
			# See if the signal's connection count was saved...
			if (json_tree[str(position_of_node_in_list)].has("DSCN_Connection_Count_" + str(i))):
				# If the signal's connection count was saved, then get it and assign it to connection_count.
				var connection_count = json_tree[str(position_of_node_in_list)]["DSCN_Connection_Count_" + str(i)]
				
				# Go through each of the saved connections...
				for j in range(0, connection_count):
					# Get the signal connection data and assign it to signal_connection.
					var signal_connection = json_tree[str(position_of_node_in_list)]["DSCN_Signal_" + str(j)]
					
					# Connect the signal.
					node.connect(signal_connection["signal"], node_list[signal_connection["target"]], 
								signal_connection["method"], signal_connection["binds"], signal_connection["flags"]);
	

# ==========================================

