extends Control

# Dependency comes from the LayerRenderers-Node which should always be above in the tree
var layer: Layer
var raster_icon = preload("res://Resources/Icons/ColorOpenMoji/raster.svg")
var feature_icon = preload("res://Resources/Icons/ColorOpenMoji/vector.svg")
var terrain_icon = preload("res://Resources/Icons/ColorOpenMoji/world.svg")

onready var icon = get_node("RightContainer/Icon")
onready var visibility_button = get_node("RightContainer/VisibilityBox/VisibilityButton")
onready var color_tag = get_node("RightContainer/VisibilityBox/ColorRect")
onready var edit_button = get_node("LeftContainer/Edit")
onready var edit_window = get_node("EditMenu")
onready var layer_name = get_node("RightContainer/Name")


func _ready():
	if layer is RasterLayer:
		icon.texture = raster_icon
	elif layer is FeatureLayer:
		icon.texture = feature_icon
	elif layer.render_type == layer.RenderType.TERRAIN:
		icon.texture = terrain_icon
	
	edit_button.connect("pressed", self, "_pop_edit")
	edit_window.connect("change_color_tag", self, "_change_color_tag")
	visibility_button.connect("toggled", self, "_layer_change_visibility")
	
	if layer != null:
		edit_window.layer = layer
		layer_name.text = layer.name


func _pop_edit():
	edit_window.popup()


func _change_color_tag(color: Color):
	color_tag.color = color


func _layer_change_visibility(is_hidden: bool):
	layer.is_visible = !is_hidden
