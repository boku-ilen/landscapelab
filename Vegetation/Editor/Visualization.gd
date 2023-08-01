extends Node3D


func _ready():
	add_child(Vegetation.get_renderers())


# Called when the node enters the scene tree for the first time.
func update_visualization(group_id):
	# Generate DHM and Splatmap for this
	var splat_image = Image.create(1, 1, false, Image.FORMAT_R8)
	splat_image.set_pixel(0, 0, Color(group_id / 255.0, 0, 0))
	
	var splat_texture = ImageTexture.create_from_image(splat_image)
	
	for layer in get_node("VegetationRenderers").get_children():
		layer.splatmap = splat_texture
		layer.update_textures_with_images([group_id])
		layer.apply_data()
	
	# Update ground texture if available
	var ground_texture = Vegetation.groups[group_id].get_ground_texture("albedo")
	var normal_texture = Vegetation.groups[group_id].get_ground_texture("normal")
	var ambient_texture = Vegetation.groups[group_id].get_ground_texture("ambient")
	var specular_texture = Vegetation.groups[group_id].get_ground_texture("specular")
	var roughness_texture = Vegetation.groups[group_id].get_ground_texture("roughness")
	
	if ground_texture:
		$GroundMesh.get_surface_override_material(0).set_shader_parameter("size_m", 500)
		$GroundMesh.get_surface_override_material(0).set_shader_parameter("texture_size_m",
				Vegetation.groups[group_id].ground_texture.size_m)
		
		$GroundMesh.get_surface_override_material(0).set_shader_parameter("albedo_tex", ground_texture)
		$GroundMesh.get_surface_override_material(0).set_shader_parameter("normal_tex", normal_texture)
		$GroundMesh.get_surface_override_material(0).set_shader_parameter("ao_tex", ambient_texture)
		$GroundMesh.get_surface_override_material(0).set_shader_parameter("specular_tex", specular_texture)
		$GroundMesh.get_surface_override_material(0).set_shader_parameter("roughness_tex", roughness_texture)
	
	if Vegetation.groups[group_id].fade_texture:
		var fade_texture = Vegetation.groups[group_id].get_fade_texture("albedo")
		var fade_normals = Vegetation.groups[group_id].get_fade_texture("normal")
		
		$GroundMesh.get_surface_override_material(0).set_shader_parameter("has_distance_tex", true)
		$GroundMesh.get_surface_override_material(0).set_shader_parameter("distance_tex", fade_texture)
		$GroundMesh.get_surface_override_material(0).set_shader_parameter("distance_normals", fade_normals)
		$GroundMesh.get_surface_override_material(0).set_shader_parameter("distance_tex_start", 10)
		$GroundMesh.get_surface_override_material(0).set_shader_parameter("distance_texture_size_m", Vegetation.groups[group_id].fade_texture.size_m)
	else:
		$GroundMesh.get_surface_override_material(0).set_shader_parameter("has_distance_tex", false)
