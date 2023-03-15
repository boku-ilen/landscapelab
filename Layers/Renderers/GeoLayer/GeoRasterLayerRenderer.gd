extends GeoLayerRenderer


@export var size_buffer_factor: float = 1.5

@onready var plane: MeshInstance2D = get_node("TexturePlane")


# as exposed in https://docs.godotengine.org/en/latest/classes/class_image.html#enum-image-format
var format: int
var mesh_size: Vector2

var r_func = func(plane, texture):
	if not plane.material:
		plane.material = ShaderMaterial.new()
		plane.material.shader = load("res://Layers/Renderers/GeoLayer/FORMAT_RF.gdshader")
	plane.get_material().set_shader_parameter("tex", texture)
	plane.get_material().set_shader_parameter("min_val", geo_raster_layer.get_min())
	plane.get_material().set_shader_parameter("max_val", geo_raster_layer.get_max())
var rgb_func = func(plane, texture): plane.texture = texture

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
		format = raster_layer.get_image(
			0,0,1.0,1,0).get_image_texture().get_format()

var current_texture


func load_new_data():
	var position_x = center[0]
	var position_y = center[1]
	
	# Geodot will always load a square and rectangles are not possible
	# => get the long side to make sure the canvas is filled
	var long_side = max(viewport_size.x, viewport_size.y)
	# Apply the size to the mesh and add some additional buffer
	mesh_size = (Vector2.ONE * long_side) / zoom
	var top_left_x = position_x - mesh_size.x / 2
	var top_left_y = position_y + mesh_size.y / 2
	
	if geo_raster_layer:
		var current_tex_image = geo_raster_layer.get_image(
			top_left_x,
			top_left_y,
			long_side / zoom.x,
			int(long_side * size_buffer_factor),
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


func get_debug_info() -> String:
	return "GeoRasterLayer."
