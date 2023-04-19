extends Node

#
# Simplified access to screenshotting
#

# Will be automatically set from the world once the positionmanager is loaded
var pos_manager

signal screenshot_finished


func _input(event):
	if event.is_action_pressed("screenshot"): screenshot()


func screenshot(
					image_name := "user://photo-%s-%s.png" % \
						[Time.get_datetime_string_from_system(),
						pos_manager.get_center_node_world_position()],
					upscale_viewport := 1.5,
					plant_extent := 5,
					name_extension := ""
				):
	if image_name == null or image_name == "": 
		image_name = "user://photo-%s-%s%s.png" % \
					[Time.get_datetime_string_from_system(),
					pos_manager.get_center_node_world_position(),
					name_extension]
						
	var previous_viewport_size = pos_manager.get_viewport().size
	var previous_plant_extent_factor = Vegetation.plant_extent_factor
	
	# Tweak anti-aliasing to be optimal for screenshotting and
	# disable taa because it messes up the image
	var msaa_before = pos_manager.get_viewport().msaa_3d
	var taa_before = pos_manager.get_viewport().is_using_taa()
	pos_manager.get_viewport().set_use_taa(false)
	pos_manager.get_viewport().set_msaa_3d(Viewport.MSAA_MAX)
	
	pos_manager.get_viewport().get_parent().stretch = false
	pos_manager.get_viewport().size = previous_viewport_size * upscale_viewport
	Vegetation.plant_extent_factor = plant_extent
	
	#await get_tree().create_timer(1).timeout
	
	RenderingServer.force_sync()
	RenderingServer.force_draw()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	# get data of the viewport
	var image = pos_manager.get_viewport().get_texture().get_image()
	
	# save to a file
	image.save_png(image_name)
	
	# Reset to prior configuration
	pos_manager.get_viewport().get_parent().stretch = true
	Vegetation.plant_extent_factor = previous_plant_extent_factor
	pos_manager.get_viewport().set_use_taa(taa_before)
	pos_manager.get_viewport().set_msaa_3d(msaa_before)
	
	RenderingServer.force_sync()
	RenderingServer.force_draw()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	screenshot_finished.emit()
