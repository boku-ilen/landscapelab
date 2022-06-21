extends Node

#
# Simplified access to screenshotting
#

# Will be automatically set from the world once the positionmanager is loaded
var pos_manager


func _input(event):
	if event.is_action_pressed("screenshot"): screenshot()


func screenshot(
					image_name := "user://photo-%d-%s.png" % \
						[OS.get_system_time_msecs(),
						pos_manager.get_center_node_world_position()],
					upscale_viewport := 1.5,
					plant_extent := 5,
					name_extension := ""
				):
	if image_name == null or image_name == "": 
		image_name = "user://photo-%d-%s%s.png" % \
					[OS.get_system_time_msecs(),
					pos_manager.get_center_node_world_position(),
					name_extension]
						
	var previous_viewport_size = pos_manager.get_viewport().size
	var previous_plant_extent_factor = Vegetation.plant_extent_factor
	
	pos_manager.get_viewport().size = previous_viewport_size * upscale_viewport
	Vegetation.plant_extent_factor = plant_extent
	
	VisualServer.force_sync()
	VisualServer.force_draw()
	
	# get data of the viewport and flip (because ... it is flipped
	var image = pos_manager.get_viewport().get_texture().get_data()
	image.flip_y()

	# save to a file
	image.save_png(image_name)
	
	pos_manager.get_viewport().size = previous_viewport_size
	Vegetation.plant_extent_factor = previous_plant_extent_factor
	
	VisualServer.force_sync()
	VisualServer.force_draw()
