extends SpecificLayerUI


var veg_edit_start_scene = preload("res://Vegetation/Editor/VegetationEditorStarter.tscn")


func _ready():
	$VegEditButton.connect("pressed", self, "open_vegetation_editor")


func open_vegetation_editor():
	$VegEditButton/VegEditDialog.add_child(veg_edit_start_scene.instance())
	$VegEditButton/VegEditDialog.popup()


func assign_specific_layer_info(layer: Layer):
	if layer.render_info == null:
		layer.render_info = Layer.VegetationRenderInfo.new()
	
	var height_layer = $HSplitContainer/RightBox/HeightChooser.get_geo_layer(true)
	var landuse_layer = $HSplitContainer/RightBox/LanduseChooser.get_geo_layer(true)

	if !validate(landuse_layer) or !validate(height_layer):
		print_warning("Texture- or height-layer is invalid!")
		return
	
	layer.render_info.height_layer = height_layer.clone()
	layer.render_info.landuse_layer = landuse_layer.clone()


func init_specific_layer_info(layer):
	$HSplitContainer/RightBox/HeightChooser.init_from_layer(
		layer.render_info.height_layer)
	$HSplitContainer/RightBox/LanduseChooser.init_from_layer(
		layer.render_info.landuse_layer)
