extends SpecificLayerUI


var veg_edit_start_scene = preload("res://Vegetation/Editor/VegetationEditorStarter.tscn")


func _ready():
	$VegEditButton.connect("pressed", self, "open_vegetation_editor")


func open_vegetation_editor():
	$VegEditButton/VegEditDialog.add_child(veg_edit_start_scene.instance())
	$VegEditButton/VegEditDialog.popup()


func assign_specific_layer_info(layer: Layer):
	layer.render_info = Layer.VegetationRenderInfo.new()
	# TODO: Also set properties of thar RenderInfo according to the UI selections
