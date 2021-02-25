extends SpecificLayerUI


onready var geodata_objects: OptionButton = get_node("RightBox/GeodataChooserPoint/OptionButton")
onready var geodata_height: OptionButton = get_node("RightBox/GeodataChooserHeight/OptionButton")
onready var file_path_object_scene = get_node("RightBox/ObjectChooser/FileName")


func assign_specific_layer_info(layer: Layer):
	if layer.render_info == null:
		layer.render_info = Layer.ObjectRenderInfo.new()

	# Obtain the point data where the object shall be set
	if not geodata_objects.get_selected_id() < geodata_objects.get_item_count():
		print_warning("No object layer chosen!")

	var objects_name = geodata_objects.get_item_text(geodata_objects.get_selected_id())
	var objects_dataset = Geodot.get_dataset($RightBox/GeodataChooserPoint/FileChooser/FileName.text)
	if !validate(objects_dataset):
		print_warning("Dataset for objects is not valid!")
		return

	var objects = objects_dataset.get_feature_layer(objects_name)


	# Obtain the height data, where the points will be placed upon
	if not geodata_height.get_selected_id() < geodata_height.get_item_count():
		print_warning("No height layer chosen!")

	var height_name = geodata_height.get_item_text(geodata_height.get_selected_id())
	var height_dataset = Geodot.get_dataset($RightBox/GeodataChooserHeight/FileChooser/FileName.text)
	if !validate(height_dataset):
		print_warning()
		return

	var height = height_dataset.get_raster_layer(height_name)

	if !validate(objects) or !validate(height):
		print_warning("Object- or height-layer is not valid!")
		return

	var file2Check = File.new()
	var is_valid_spatial = file2Check.file_exists(file_path_object_scene.text)
<<<<<<< HEAD
	if !is_valid_spatial:
		print_warning("Object scene is not a valid scene!")
=======
	if !validate(objects) or !validate(height) or !is_valid_spatial:
		print_warning("Invalid layers!")
>>>>>>> e1676f8788c962ffed85820cc59c5198cf2ee977
		return

	var height_layer = RasterLayer.new()
	height_layer.geo_raster_layer = height
	height_layer.name = height.resource_name

	layer.geo_feature_layer = objects
	layer.render_type = Layer.RenderType.OBJECT
	layer.render_info.object = load(file_path_object_scene.text)
	layer.render_info.ground_height_layer = height_layer.clone()


# TODO: implement this function accordingly, so when editing an existing one, all configurations will be applied
func init_specific_layer_info(layer):
	if layer == null:
		return

	#file_path_height =
	#file_path_
