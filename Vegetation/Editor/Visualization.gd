extends Spatial


func _ready():
	add_child(Vegetation.get_renderers())


# Called when the node enters the scene tree for the first time.
func update_visualization(group_id):
	# Generate DHM and Splatmap for this
	var splat_image = Image.new()
	
	splat_image.create(1, 1, false, Image.FORMAT_R8)
	splat_image.lock()
	splat_image.set_pixel(0, 0, Color(group_id / 255.0, 0, 0))
	splat_image.unlock()
	
	var splat_texture = ImageTexture.new()
	splat_texture.create_from_image(splat_image)
	
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
		$GroundMesh.get_surface_material(0).set_shader_param("size_m", 500)
		$GroundMesh.get_surface_material(0).set_shader_param("texture_size_m",
				Vegetation.groups[group_id].ground_texture.size_m)
		
		$GroundMesh.get_surface_material(0).set_shader_param("albedo_tex", ground_texture)
		$GroundMesh.get_surface_material(0).set_shader_param("normal_tex", normal_texture)
		$GroundMesh.get_surface_material(0).set_shader_param("ao_tex", ambient_texture)
		$GroundMesh.get_surface_material(0).set_shader_param("specular_tex", specular_texture)
		$GroundMesh.get_surface_material(0).set_shader_param("roughness_tex", roughness_texture)
	
	if Vegetation.groups[group_id].fade_texture:
		var fade_texture = Vegetation.groups[group_id].get_fade_texture("albedo")
		var fade_normals = Vegetation.groups[group_id].get_fade_texture("normal")
		
		$GroundMesh.get_surface_material(0).set_shader_param("has_distance_tex", true)
		$GroundMesh.get_surface_material(0).set_shader_param("distance_tex", fade_texture)
		$GroundMesh.get_surface_material(0).set_shader_param("distance_normals", fade_normals)
		$GroundMesh.get_surface_material(0).set_shader_param("distance_tex_start", 10)
		$GroundMesh.get_surface_material(0).set_shader_param("distance_texture_size_m", Vegetation.groups[group_id].fade_texture.size_m)
	else:
		$GroundMesh.get_surface_material(0).set_shader_param("has_distance_tex", false)
