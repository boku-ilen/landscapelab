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
					upscale_viewport := 2.0,
					name_extension := ""
				):
	var image_name = "photo-%s-%s%s.png" % \
					[Time.get_datetime_string_from_system(),
					pos_manager.get_center_node_world_position(),
					name_extension]
	
	image_name = "user://" + image_name.validate_filename()
	
	var previous_viewport_size = pos_manager.get_viewport().size
	
	# Tweak anti-aliasing to be optimal for screenshotting and
	# disable taa because it messes up the image
	var msaa_before = pos_manager.get_viewport().msaa_3d
	var taa_before = pos_manager.get_viewport().is_using_taa()
	pos_manager.get_viewport().set_use_taa(false)
	pos_manager.get_viewport().set_msaa_3d(Viewport.MSAA_MAX)
	
	pos_manager.get_viewport().get_parent().stretch = false
	pos_manager.get_viewport().size = previous_viewport_size * upscale_viewport		
	
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
	pos_manager.get_viewport().set_use_taa(taa_before)
	pos_manager.get_viewport().set_msaa_3d(msaa_before)
	
	RenderingServer.force_sync()
	RenderingServer.force_draw()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	screenshot_finished.emit()
