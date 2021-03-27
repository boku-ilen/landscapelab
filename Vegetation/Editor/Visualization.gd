extends Spatial


export(Resource) var vegetation_layer_composition


func _ready():
	add_child(vegetation_layer_composition.get_renderers("VegetationRenderers"))


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
		layer.update_textures_with_images(null, splat_texture, [group_id])
	
	# Update ground texture if available
	var ground_texture = Vegetation.groups[group_id].get_ground_texture("albedo")
	var normal_texture = Vegetation.groups[group_id].get_ground_texture("normal")
	
	if ground_texture:
		$GroundMesh.get_surface_material(0).albedo_texture = ground_texture
		$GroundMesh.get_surface_material(0).normal_texture = normal_texture
