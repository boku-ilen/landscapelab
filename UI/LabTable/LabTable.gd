extends Control


@export var geo_layers: Node2D

var current_goc_name = "Wind Turbines"


func _ready():
	# FIXME: this will probably removed/rewritten in a later step
	$LLConfigSetup.applied_configuration.connect(geo_layers.setup)
	$Button.toggled.connect(set_workshop_mode)
	$LLConfigSetup.setup()
	
	# Display camera extent on overview
	var extent_visualizer = $SubViewportContainer/PanelContainer/ControlContainer/VBox/SubViewportContainer/SubViewport/ReferenceRect
	geo_layers.camera_extent_changed.connect(func(camera_extent):
		extent_visualizer.position = camera_extent.center - extent_visualizer.size / 2
		extent_visualizer.size = camera_extent.extent)
	
	# Use input on overview map as "recenter"
	$SubViewportContainer/PanelContainer/ControlContainer.recenter.connect(func(center):
		$SubViewportContainer/SubViewport/Camera2D.set_offset_and_emit(center))
	set_workshop_mode(true)
	
	print(GameSystem.current_game_mode.game_object_collections)


func set_workshop_mode(active: bool): 
	var action_handler = $SubViewportContainer/ActionHandler
	if not active: 
		action_handler.current_action = null
		return
	
	var primary_func = func(event, cursor, state_dict):
		var collection = GameSystem.current_game_mode.game_object_collections[current_goc_name]
		var new_game_object = GameSystem.create_new_game_object(collection,
			Vector3(
				cursor.global_position.x - geo_layers.offset.x + geo_layers.center.x,
				0,
				cursor.global_position.y - geo_layers.offset.y - geo_layers.center.y)
		)
		
		print(new_game_object)
		
		if not new_game_object:
			pass # TODO: Display "forbidden" symbol
	
	var edit_action = EditingAction.new(primary_func)
	action_handler.set_current_action(edit_action)
