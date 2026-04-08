extends Object
class_name BillboardSpritesheetGenerator


static func create_billboard_sprites_for_mesh(mesh: Mesh, resolution := 1024) -> Array[Image]:
	var render_scenario = RenderingServer.scenario_create()

	var render_viewport = RenderingServer.viewport_create()
	RenderingServer.viewport_set_size(render_viewport, resolution, resolution)
	RenderingServer.viewport_set_update_mode(render_viewport, RenderingServer.VIEWPORT_UPDATE_ALWAYS)
	RenderingServer.viewport_set_transparent_background(render_viewport, true)
	RenderingServer.viewport_set_scenario(render_viewport, render_scenario)
	var render_texture = RenderingServer.viewport_get_texture(render_viewport)

	var render_instance = RenderingServer.instance_create()
	RenderingServer.instance_set_base(render_instance, mesh)
	RenderingServer.instance_set_transform(render_instance, Transform3D.IDENTITY)
	RenderingServer.instance_set_scenario(render_instance, render_scenario)

	var camera = RenderingServer.camera_create()
	RenderingServer.camera_set_orthogonal(camera, 1, 0.05, 1.0)

	RenderingServer.viewport_attach_camera(render_viewport, camera)
	RenderingServer.viewport_set_active(render_viewport, true)

	RenderingServer.force_sync()
	RenderingServer.force_draw()

	var render_modes = [
		RenderingServer.VIEWPORT_DEBUG_DRAW_UNSHADED,
		RenderingServer.VIEWPORT_DEBUG_DRAW_NORMAL_BUFFER
	]
	var camera_transforms = [
		Transform3D.IDENTITY.translated(Vector3(0.0, 0.5, 0.5)),
		Transform3D.IDENTITY.rotated(Vector3.UP, -PI / 2.0).translated(Vector3(-0.5, 0.5, 0.0))
	]
	
	var results : Array[Image] = []

	for render_mode in render_modes:
		RenderingServer.viewport_set_debug_draw(render_viewport, render_mode)
		
		var images = []
		
		for camera_transform in camera_transforms:
			RenderingServer.camera_set_transform(camera, camera_transform)
			
			RenderingServer.force_sync()
			RenderingServer.force_draw()
			
			images.append(RenderingServer.texture_2d_get(render_texture))
		
		var total_image = Image.create(
			resolution * images.size(),
			resolution,
			true,
			images.front().get_format()
		)
		
		for image_index in range(images.size()):
			total_image.blit_rect(
				images[image_index],
				Rect2i(0, 0, resolution, resolution),
				Vector2i(resolution * image_index, 0)
			)
		
		total_image.generate_mipmaps()
		
		results.append(total_image)
	
	# Clean up
	RenderingServer.free_rid(camera)
	RenderingServer.free_rid(render_instance)
	RenderingServer.free_rid(render_viewport)
	RenderingServer.free_rid(render_texture)
	RenderingServer.free_rid(render_scenario)
	
	return results
