extends SpecificLayerUI


onready var geodata_objects: OptionButton = get_node("RightBox/GeodataChooserPoint/OptionButton")
onready var geodata_height: OptionButton = get_node("RightBox/GeodataChooserHeight/OptionButton")

# FIXME: These don't exist, can they be removed?
onready var file_path_objects = get_node("RightBox/GeodataChooser/FileChooser/FileName")
onready var file_path_object_scene = get_node("RightBox/ObjectChooser/FileName")


func assign_specific_layer_info(layer: Layer):
	if layer.render_info == null:
		layer.render_info = Layer.ObjectRenderInfo.new()
	
	# Obtain the point data where the object shall be set
	var objects_name = geodata_objects.get_item_text(geodata_objects.get_selected_id())
	var objects_dataset = Geodot.get_dataset($RightBox/GeodataChooserPoint/FileChooser/FileName.text)
	if !validate(objects_dataset):
		print_warning()
		return
	
	var objects = objects_dataset.get_feature_layer(objects_name)
	
	# Obtain the height data, where the points will be placed upon
	# FIXME: produces "Index p_idx = 0 is out of bounds (items.size() = 0)._on_confirm()"
	var height_name = geodata_height.get_item_text(geodata_height.get_selected_id())
	
	# For the height, we open a Layer directly without a dataset in-between, because that's how
	#  things like GeoTIFFs are handled
	var height = Geodot.get_raster_layer($RightBox/GeodataChooserHeight/FileChooser/FileName.text)
	
	var file2Check = File.new()
	var is_valid_spatial = file2Check.file_exists(file_path_object_scene.text)
	if !validate(objects) or !validate(height) or !is_valid_spatial:
		print_warning()
		return
	
	var height_layer = RasterLayer.new()
	height_layer.geo_raster_layer = height
	height_layer.name = height.resource_name
	
	layer.geo_feature_layer = objects
	layer.render_type = Layer.RenderType.OBJECT
	layer.render_info.object = load(file_path_object_scene.text)
	layer.render_info.ground_height_layer = height_layer.clone()


func init_specific_layer_info(layer):
	if layer == null:
		return
	
	#file_path_height = 
	#file_path_
	
	
