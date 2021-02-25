extends SpecificLayerUI


onready var color_checkbox = get_node("RightBox/CheckBox")
onready var label_color_min = get_node("LeftBox/ColorMin")
onready var label_color_max = get_node("LeftBox/ColorMax")
onready var button_color_min = get_node("RightBox/ButtonMin")
onready var button_color_max = get_node("RightBox/ButtonMax")
onready var geodata_height: OptionButton = get_node("RightBox/GeodataChooserHeight/OptionButton")
onready var geodata_texture: OptionButton = get_node("RightBox/GeodataChooserTexture/OptionButton")
onready var file_path_height = get_node("RightBox/GeodataChooser/FileChooser/FileName")
onready var file_path_path = get_node("RightBox/GeodataChooser/FileChooser/FileName")


func _ready():
	color_checkbox.connect("toggled", self, "_toggle_color_menu")
	button_color_min.connect("pressed", self, "_pop_color_picker", [button_color_min])
	button_color_max.connect("pressed", self, "_pop_color_picker", [button_color_max])


func _toggle_color_menu(toggled: bool):
	button_color_max.visible = toggled
	label_color_max.visible = toggled
	button_color_min.visible = toggled
	label_color_min.visible = toggled


func _pop_color_picker(button: Button):
	var color_dialog = button.get_node("ConfirmationDialog")
	var color_picker = color_dialog.get_node("ColorPicker")
	color_dialog.connect("confirmed", self, "_set_color", [button, color_picker])
	color_dialog.popup(Rect2(button.rect_global_position, Vector2(0,0)))


func _set_color(button: Button, color_picker: ColorPicker):
	button.color = color_picker.color


func assign_specific_layer_info(layer):
	if layer.render_info == null:
		layer.render_info = Layer.TerrainRenderInfo.new()
	
	var texture_name = geodata_texture.get_item_text(geodata_texture.get_selected_id())
	var texture_dataset = Geodot.get_dataset($RightBox/GeodataChooserTexture/FileChooser/FileName.text)
	var texture = texture_dataset.get_raster_layer(texture_name)
		
	var height_name = geodata_height.get_item_text(geodata_height.get_selected_id())
	var height_dataset = Geodot.get_dataset($RightBox/GeodataChooserHeight/FileChooser/FileName.text)
	var height = height_dataset.get_raster_layer(height_name)
	
	if !texture or !height or !texture.is_valid() or !height.is_valid():
		print_warning()
		return

	# Heightmap
	var height_layer = RasterLayer.new()
	height_layer.geo_raster_layer = height
	height_layer.name = height.resource_name

	# Orthophoto
	var ortho_layer = RasterLayer.new()
	ortho_layer.geo_raster_layer = texture
	ortho_layer.name = texture.resource_name

	Layers.add_layer(height_layer)
	Layers.add_layer(ortho_layer)

	layer.render_info.height_layer = height_layer.clone()
	layer.render_info.texture_layer = ortho_layer.clone()
	layer.render_info.is_color_shaded = color_checkbox.pressed
	layer.render_info.max_color = button_color_max.color
	layer.render_info.min_color = button_color_min.color


func init_specific_layer_info(layer):
	if layer == null:
		return
	
	#file_path_height = 
	#file_path_
	
	
