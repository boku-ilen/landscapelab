extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


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
	
	$VegetationLayer.update_textures_with_images(null, splat_texture, [group_id])


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
