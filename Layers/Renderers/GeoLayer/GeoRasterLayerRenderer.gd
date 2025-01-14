extends GeoLayerRenderer


@export var size_buffer_factor: float = 1.5

@onready var plane: MeshInstance2D = get_node("TexturePlane")


# as exposed in https://docs.godotengine.org/en/latest/classes/class_image.html#enum-image-format
var format: int
var mesh_size: Vector2

var r_func = func(existing_plane, texture):
	if not existing_plane.material:
		existing_plane.material = ShaderMaterial.new()
		existing_plane.material.shader = load("res://Layers/Renderers/GeoLayer/FORMAT_RF.gdshader")
		var gradient_tex = GradientTexture1D.new()
		gradient_tex.gradient = layer_definition.render_info.gradient.duplicate()
		existing_plane.get_material().set_shader_parameter("gradient", gradient_tex)
		existing_plane.get_material().set_shader_parameter("min_val", layer_definition.render_info.min_val)
		existing_plane.get_material().set_shader_parameter("max_val", layer_definition.render_info.max_val)
		existing_plane.get_material().set_shader_parameter("NODATA", layer_definition.render_info.no_data)
	existing_plane.get_material().set_shader_parameter("tex", texture)
var rgb_func = func(existing_plane, texture): existing_plane.texture = texture

var format_function_dict = {
	Image.FORMAT_RGB8: rgb_func,
	Image.FORMAT_RGBA8: rgb_func,
	Image.FORMAT_RF: r_func, 
	Image.FORMAT_R8: r_func
}

var geo_raster_layer: GeoRasterLayer : 
	get: return geo_raster_layer
	set(raster_layer):
		geo_raster_layer = raster_layer
		
		# Just some dummy values for getting the format
		format = raster_layer.get_format()

var current_texture


func load_new_data():
	var position_x: float = center[0]
	var position_y: float = center[1]
	
	# Geodot will always load a square and rectangles are not possible
	# => get the long side to make sure the canvas is filled
	var long_side = max(viewport_size.x, viewport_size.y)
	# Apply the size to the mesh and add some additional buffer
	mesh_size = (Vector2.ONE * long_side) / zoom
	
	var size_meters = long_side / zoom.x
	var size_pixels = int(long_side)
	
	var pixel_size =  size_meters / size_pixels
	
	var top_left = Vector2(
		snappedf(position_x - mesh_size.x / 2, pixel_size),
	 	snappedf(position_y + mesh_size.y / 2, pixel_size)
	)
	
	var bot_right = Vector2(
		snappedf(position_x + mesh_size.x / 2, pixel_size),
		snappedf(position_y - mesh_size.y / 2, pixel_size)
	)
	
	if geo_raster_layer:
		var current_tex_image = geo_raster_layer.get_image(
			top_left.x,
			top_left.y,
			size_meters,
			size_pixels,
			0
		)
		
		if current_tex_image.is_valid():
			current_texture = current_tex_image.get_image_texture()


func apply_new_data():
	if current_texture:
		format_function_dict.get(format).call(plane, current_texture)
		# Only apply the mesh_size after the new texture has been applied
		# otherwise it will look clunky
		plane.mesh.size = mesh_size
		plane.visibility_layer = visibility_layer


func get_debug_info() -> String:
	return "GeoRasterLayer."
