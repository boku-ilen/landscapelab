extends GeoLayerRenderer


@export var layer_resolution: int = 1000

@onready var plane: MeshInstance2D = get_node("TexturePlane")


# as exposed in https://docs.godotengine.org/en/latest/classes/class_image.html#enum-image-format
var format: int

var r_func = func(plane, texture):
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
			0,
			0,
			1.0,
			1,
			0
		).get_image_texture().get_format()

var current_texture


func load_new_data():
	var position_x = center[0]
	var position_y = center[1]
	
	var top_left_x = position_x - plane.mesh.size.x / 2
	var top_left_y = position_y + plane.mesh.size.y / 2
	
	if geo_raster_layer:
		var current_tex_image = geo_raster_layer.get_image(
			top_left_x,
			top_left_y,
			10000.0,
			layer_resolution,
			0
		)
		
		if current_tex_image.is_valid():
			current_texture = current_tex_image.get_image_texture()


func apply_new_data():
	if current_texture:
		format_function_dict.get(format).call(plane, current_texture)


func get_debug_info() -> String:
	return "GeoRasterLayer."
