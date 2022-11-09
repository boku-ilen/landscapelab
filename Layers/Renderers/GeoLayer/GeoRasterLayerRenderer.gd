extends GeoLayerRenderer


@export var layer_resolution: int = 100

@onready var plane = get_node("TexturePlane")

var geo_raster_layer: GeoRasterLayer
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
			plane.mesh.size.x,
			layer_resolution,
			1
		)
		
		if current_tex_image.is_valid():
			current_texture = current_tex_image.get_image_texture()


func apply_new_data():
	if current_texture:
		plane.material_override.albedo_texture = current_texture


func get_debug_info() -> String:
	return "GeoRasterLayer."
