extends RefCounted
class_name TerraformingTexture

var width: int = 0

var texture: ImageTexture
var weights: ImageTexture

var _texture_data: PackedByteArray
var _texture_image: Image

var _weights_data: PackedByteArray
var _weights_image: Image


func _init(texture_width: int):
	width = texture_width
	
	_texture_data.resize(width * width * 4)
	_weights_data.resize(width * width * 4)
	
	reset()
	
	_texture_image = Image.create(width, width, false, Image.FORMAT_RF)
	texture = ImageTexture.create_from_image(_texture_image)
	
	_weights_image = Image.create(width, width, false, Image.FORMAT_RF)
	weights = ImageTexture.create_from_image(_weights_image)


func reset() -> void:
	_texture_data.fill(0)
	_weights_data.fill(0)


func update_texture() -> void:
	_texture_image.set_data(width, width, false, Image.FORMAT_RF, _texture_data)
	_weights_image.set_data(width, width, false, Image.FORMAT_RF, _weights_data)
	
	texture.update(_texture_image)
	weights.update(_weights_image)


func save_debug_image(location: String, name_post_fix: String = "") -> void:
	_weights_image.save_png("%s/Terraforming_Weights_%s.png" % [location, name_post_fix])


func set_pixel(position: int, value: float, weight: float) -> void:
	# Outside of texture
	if position < 0 || position >= width * width:
		return
	
	var old_height = _texture_data.decode_float(position * 4)
	var old_weight = _weights_data.decode_float(position * 4)
	
	# Check if height should be overwritten
	if old_height == 0.0 or old_height > value:
		_texture_data.encode_float(position * 4, value)
	
	# Check if weight should be overwritten
	if old_weight == 0.0 or old_weight < weight:
		_weights_data.encode_float(position * 4, weight)
