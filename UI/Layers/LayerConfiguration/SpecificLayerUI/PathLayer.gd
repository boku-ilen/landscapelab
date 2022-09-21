extends SpecificLayerUI


@onready var geodata_paths: OptionButton = get_node("RightBox/PathChooser/OptionButton")
@onready var geodata_height: OptionButton = get_node("RightBox/HeightChooser/OptionButton")
@onready var file_path_line_scene = get_node("RightBox/ProfileChooser/FileName")


func _ready():
	$RightBox/Button.connect("pressed",Callable(self,"_open_profile_editor"))


func _open_profile_editor():
	$RightBox/Button/ProfileEditor.popup_centered()


func assign_specific_layer_info(layer: Layer):
	if layer.render_info == null:
		layer.render_info = Layer.PathRenderInfo.new()

	# Obtain the point data where the object shall be set
	if not geodata_paths.get_selected_id() < geodata_paths.get_item_count():
		print_warning("No object layer chosen!")

	var paths_name = geodata_paths.get_item_text(geodata_paths.get_selected_id())
	var paths_dataset = Geodot.get_dataset($RightBox/PathChooser/FileChooser/FileName.text)
	if !validate(paths_dataset):
		print_warning("Dataset for objects is not valid!")
		return

	var paths = paths_dataset.get_feature_layer(paths_name)


	# Obtain the height data, where the points will be placed upon
	if not geodata_height.get_selected_id() < geodata_height.get_item_count():
		print_warning("No height layer chosen!")

	var height_name = geodata_height.get_item_text(geodata_height.get_selected_id())
	var height_dataset = Geodot.get_dataset($RightBox/HeightChooser/FileChooser/FileName.text)
	if !validate(height_dataset):
		print_warning()
		return

	var height = height_dataset.get_raster_layer(height_name)

	if !validate(paths) or !validate(height):
		print_warning("Object- or height-layer is not valid!")
		return

	var file2Check = File.new()
	var is_valid_spatial = file2Check.file_exists(file_path_line_scene.text)
	
	if !is_valid_spatial:
		print_warning("Invalid profile!")
		return

	var height_layer = RasterLayer.new()
	height_layer.geo_raster_layer = height
	height_layer.name = height.resource_name

	layer.geo_feature_layer = paths
	layer.render_type = Layer.RenderType.PATH
	layer.render_info.line_visualization = load(file_path_line_scene.text)
	layer.render_info.ground_height_layer = height_layer.clone()
