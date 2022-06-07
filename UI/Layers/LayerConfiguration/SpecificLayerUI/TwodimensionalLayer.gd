extends SpecificLayerUI


onready var geodata_texture: OptionButton = get_node("RightBox/GeodataChooserTexture/OptionButton")


func assign_specific_layer_info(layer: Layer):
	if layer.render_info == null:
		layer.render_info = Layer.TwoDimensionalInfo.new()
	
	# Obtain the height data, where the points will be placed upon
	if not geodata_texture.get_selected_id() < geodata_texture.get_item_count():
		print_warning("No height layer chosen!")

	var texture_name = geodata_texture.get_item_text(geodata_texture.get_selected_id())
	var texture_dataset = Geodot.get_dataset($RightBox/GeodataChooserTexture/FileChooser/FileName.text)
	if !validate(texture_dataset):
		print_warning()
		return

	var texture = texture_dataset.get_raster_layer(texture_name)

	if !validate(texture):
		print_warning("Object- or height-layer is not valid!")
		return

	var texture_layer = RasterLayer.new()
	texture_layer.geo_raster_layer = texture
	texture_layer.name = texture.resource_name

	layer.render_type = Layer.RenderType.TWODIMENSIONAL
	layer.render_info.texture_layer = texture_layer.clone()


func init_specific_layer_info(layer: Layer):
	$RightBox/GeodataChooserTexture.init_from_layer(
		layer.render_info.ground_height_layer)
