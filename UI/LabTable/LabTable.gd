extends Control


@export var geo_layers: Node2D
@export var control_ui: Control
@export var extent_visualizer: Control
@export var player_node: Node3D : 
	set(new_player):
		player_node = new_player
		if geo_layers:
			geo_layers.player_node = new_player
			
		get_parent().get_node("AtmosphereMenu/AtmosphereConfiguration/LiveWeatherService").player = new_player

@export var time_manager: TimeManager:
	set(new_time_manager):
		time_manager = new_time_manager
		get_parent().get_node("AtmosphereMenu").time_manager = new_time_manager

@export var weather_manager: WeatherManager:
	set(new_weather_manager):
		weather_manager = new_weather_manager
		get_parent().get_node("AtmosphereMenu").weather_manager = new_weather_manager
		get_parent().get_node("AtmosphereMenu/AtmosphereConfiguration/LiveWeatherService").weather_manager = new_weather_manager

# To debug it as standalone (without running the rest of the landscapelab
# it is necessary to load the configuration
@export var debug_mode := false

var current_goc_name = "Offshore Wind Farms"

var geo_transform
var goc_configuration_popup = preload("res://GameSystem/GameObjectConfiguration.tscn")

signal game_object_created(cursor_position)
signal game_object_failed(cursor_position)


func _ready():
	# In the usual setting this will be handled by the landscapelab
	if debug_mode: $LLConfigSetup.setup()
	if debug_mode: $GameModesConfigurator.load_game_mode_config()
	
	# Add map and layers from config
	$LabTableConfigurator.map_added.connect(func(layer_name, crs_from):
		control_ui.init_overview_map(layer_name)
		var center = Layers.get_geo_layer_by_name(layer_name).get_center()
		geo_layers.setup(Vector2(center.x, center.z), crs_from)
		geo_layers.set_layer_visibility(layer_name, true)
		
		geo_transform = GeoTransform.new()
		geo_transform.set_transform(3857, crs_from)
		
		var inv_geo_transform = GeoTransform.new()
		inv_geo_transform.set_transform(crs_from, 3857)
		geo_layers.geo_transform = inv_geo_transform
	)
	
	$LabTableConfigurator.new_layer.connect(func(layer_conf):
		if layer_conf["layer_name"] in Layers.layer_compositions:
			geo_layers.add_layer_composition_renderer(layer_conf)
		else: 
			geo_layers.set_layer_visibility(layer_conf["layer_name"], true, layer_conf["z_index"]))
	$LabTableConfigurator.load_table_config()
	
	# Display camera extent on overview
	geo_layers.camera_extent_changed.connect(func(camera_extent):
		extent_visualizer.position = camera_extent.center - extent_visualizer.size / 2
		extent_visualizer.size = camera_extent.extent)
	
	# Use input on overview map as "recenter"
	control_ui.recenter.connect(
		$SubViewportContainer/SubViewport/Camera2D.set_offset_and_emit)
	
	set_workshop_mode(true)
	
	# Start at a sensible zoom
	# We need to wait 1 frame because the Viewport must be done setting up
	await get_tree().process_frame
	$SubViewportContainer/SubViewport/Camera2D.do_zoom(0)
	
	$SubViewportContainer/SubViewport/Camera2D.offset_changed.connect(_on_camera_offset_changed)


func set_workshop_mode(active: bool): 
	var action_handler = $SubViewportContainer/SubViewport/Camera2D/ActionHandler
	if not active: 
		action_handler.current_action = null
		return
	
	# Primary function: creating game objects with left click
	var primary_func = func(event, cursor, state_dict):
		# Update may be 1 frame behind without this because input propagates down to cursor later
		cursor.update_from_mouse_position(event.position)
		
		var vector_3857 = Vector3(
				cursor.global_position.x - geo_layers.offset.x + geo_layers.center.x,
				0,
				-cursor.global_position.y + geo_layers.offset.y + geo_layers.center.y)
		
		var vector_local = geo_transform.transform_coordinates(vector_3857)
		
		var successful_configuration = []
		if not current_goc_name:
			game_object_failed.emit(event.position)
			return
		elif current_goc_name == "Teleport":
			if player_node:
				player_node.set_world_position(vector_local)
				game_object_created.emit(event.position)
			else:
				game_object_failed.emit(event.position)
		else:
			# Swap -z forward/backward since we're in 2D space
			vector_local.z = -vector_local.z
			
			var collection = GameSystem.current_game_mode.game_object_collections[current_goc_name]
			
			var new_game_object = GameSystem.create_new_game_object(collection, vector_local)
			
			if new_game_object:
				game_object_created.emit(event.position)
				var renderer
				for child in $SubViewportContainer/SubViewport/GeoLayerRenderers.get_children():
					if "geo_feature_layer" in child and child.geo_feature_layer.get_file_info()["name"] == collection.feature_layer.get_file_info()["name"]:
						renderer = child
				var is_any_change_allowed = collection.attributes.values().any(func(attrib): return attrib.allow_change)
				if is_any_change_allowed:
					renderer.newest_feature = new_game_object.geo_feature
			else:
				game_object_failed.emit(event.position)
	
	# Secondary function: removing game objects with right click
	var secondary_func = func(event, cursor, state_dict):
		# Update may be 1 frame behind without this because input propagates down to cursor later
		cursor.update_from_mouse_position(event.position)
		
		var vector_3857 = Vector3(
				cursor.global_position.x - geo_layers.offset.x + geo_layers.center.x,
				0,
				-cursor.global_position.y + geo_layers.offset.y + geo_layers.center.y)
		
		var vector_local = geo_transform.transform_coordinates(vector_3857)
		
		if not current_goc_name or current_goc_name == "Teleport": return
		
		var collection = GameSystem.current_game_mode.game_object_collections[current_goc_name]
		
		# Remove objects within a radius of 1m around the click
		# TODO: Expose the radius, it'll likely depend on the current_goc_name
		collection.remove_nearby_game_objects(vector_local, 200.0)
	
	var edit_action = EditingAction.new(primary_func, secondary_func)
	action_handler.set_current_action(edit_action)


func _on_camera_offset_changed(_offset, _viewport_size, _zoom):
	$LabTableCommunicator.clear_brick_memory()
