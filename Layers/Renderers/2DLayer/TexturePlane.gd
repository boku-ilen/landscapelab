extends MeshInstance3D


@export var map_resolution: int = 100


var position_x
var position_y

var texture_layer
var current_texture

signal updated_data


func _ready():
	visible = false


func build():
	var top_left_x = position_x - mesh.size.x / 2
	var top_left_y = position_y + mesh.size.y / 2
	
	# Texture2D
	if texture_layer:
		var current_tex_image = texture_layer.get_image(
			top_left_x,
			top_left_y,
			mesh.size.x,
			map_resolution,
			1
		)
		
		if current_tex_image.is_valid():
			current_texture = current_tex_image.get_image_texture()


func apply_textures():
	if current_texture:
		get_surface_override_material(0).albedo_texture = current_texture
	
	visible = true
