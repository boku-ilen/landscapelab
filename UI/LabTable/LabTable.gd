extends Control


@export var geo_layers: Node2D
@export var control_ui: Control

var current_goc_name = "Wind Turbines"

var geo_transform


func _ready():
	$LLConfigSetup.setup()
	
	# Add map and layers from config
	$LabTableConfigurator.map_added.connect(func(layer_name):
		control_ui.init_overview_map(layer_name)
		var center = Layers.get_geo_layer_by_name(layer_name).get_center()
		geo_layers.setup(Vector2(center.x, center.z))
		geo_layers.set_layer_visibility(layer_name, true))
	
	$LabTableConfigurator.new_layer.connect(func(layer_name, z_index = 0):
		geo_layers.add_layer_composition_renderer(layer_name, true, z_index))
	$LabTableConfigurator.load_table_config()
	
	# Display camera extent on overview
	var extent_visualizer = control_ui.get_node(
		"VBox/SubViewportContainer/SubViewport/ReferenceRect")
	geo_layers.camera_extent_changed.connect(func(camera_extent):
		extent_visualizer.position = camera_extent.center - extent_visualizer.size / 2
		extent_visualizer.size = camera_extent.extent)
	
	# Use input on overview map as "recenter"
	control_ui.recenter.connect(func(center):
		$SubViewportContainer/SubViewport/Camera2D.set_offset_and_emit(center))
	
	set_workshop_mode(true)
	
	# Start at a sensible zoom
	# We need to wait 1 frame because the Viewport must be done setting up
	await get_tree().process_frame
	$SubViewportContainer/SubViewport/Camera2D.do_zoom(0)
	
	geo_transform = GeoTransform.new()
	geo_transform.set_transform(3857, 31287)


func set_workshop_mode(active: bool): 
	var action_handler = $SubViewportContainer/ActionHandler
	if not active: 
		action_handler.current_action = null
		return
	
	# Primary function: creating game objects with left click
	var primary_func = func(event, cursor, state_dict):
		# Update may be 1 frame behind without this because input propagates down to cursor later
		cursor.update_from_mouse_position(event.position)
		
		var collection = GameSystem.current_game_mode.game_object_collections[current_goc_name]
		
		var vector_3857 = Vector3(
				cursor.global_position.x - geo_layers.offset.x + geo_layers.center.x,
				0,
				-cursor.global_position.y + geo_layers.offset.y + geo_layers.center.y)
		
		var vector_local = geo_transform.transform_coordinates(vector_3857)
		
		# Swap -z forward/backward since we're in 2D space
		vector_local.z = -vector_local.z
		
		var new_game_object = GameSystem.create_new_game_object(collection, vector_local)
		
		if not new_game_object:
			pass # TODO: Display "forbidden" symbol
	
	# Secondary function: removing game objects with right click
	var secondary_func = func(event, cursor, state_dict):
		# Update may be 1 frame behind without this because input propagates down to cursor later
		cursor.update_from_mouse_position(event.position)
		
		var collection = GameSystem.current_game_mode.game_object_collections[current_goc_name]
		
		var vector_3857 = Vector3(
				cursor.global_position.x - geo_layers.offset.x + geo_layers.center.x,
				0,
				-cursor.global_position.y + geo_layers.offset.y + geo_layers.center.y)
		
		var vector_local = geo_transform.transform_coordinates(vector_3857)
		
		# Remove objects within a radius of 1m around the click
		collection.remove_nearby_game_objects(vector_local, 1.0)
	
	var edit_action = EditingAction.new(primary_func, secondary_func)
	action_handler.set_current_action(edit_action)
