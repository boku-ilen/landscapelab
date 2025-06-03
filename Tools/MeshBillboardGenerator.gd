@tool
extends Node3D


@export var generate: bool :
	set(new_value):
		generate_billboard()
	
	get:
		return generate


# Called when the node enters the scene tree for the first time.
func generate_billboard():
	var last_child = get_children().back()
	
	var albedo_texture = _render_to_spritesheet(Viewport.DEBUG_DRAW_UNSHADED)
	$"1mBillboardDualtex".material_override.set_shader_parameter("albedo_tex", albedo_texture)
	albedo_texture.get_image().save_png("res://" + last_child.name + "_albedo.png")
	
	var normal_texture = _render_to_spritesheet(Viewport.DEBUG_DRAW_NORMAL_BUFFER)
	$"1mBillboardDualtex".material_override.set_shader_parameter("normal_tex", normal_texture)
	normal_texture.get_image().save_png("res://" + last_child.name + "_normal.png")


func _render_to_spritesheet(debug_draw):
	$FrontSubViewportContainer/FrontSubViewport.debug_draw = debug_draw
	$SideSubViewportContainer/SideSubViewport.debug_draw = debug_draw
	
	$FrontSubViewportContainer/FrontSubViewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	$SideSubViewportContainer/SideSubViewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	
	RenderingServer.force_draw()
	
	var front_image = $FrontSubViewportContainer/FrontSubViewport.get_texture().get_image()
	var side_image = $SideSubViewportContainer/SideSubViewport.get_texture().get_image()
	
	var total_image = Image.create(2048, 1024, true, front_image.get_format())
	
	total_image.blit_rect(front_image, Rect2i(0, 0, 1024, 1024), Vector2i(0, 0))
	total_image.blit_rect(side_image, Rect2i(0, 0, 1024, 1024), Vector2i(1024, 0))
	
	total_image.generate_mipmaps()
	
	return ImageTexture.create_from_image(total_image)
