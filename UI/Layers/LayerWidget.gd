extends Control

# TODO: Will consist of icon, text, points for "edit" and visibility (see 
# https://duckduckgo.com/?t=ffab&q=photoshop+layer&iax=images&ia=images&iai=http%3A%2F%2Fvisualizingarchitecture.com%2Fwp-content%2Fuploads%2F2014%2F10%2FLayers_0_masks_layers.jpg)

# Dependency comes from the LayerRenderers-Node which should always be above in the tree
var layer: Layer
var raster_icon = preload("res://Resources/Icons/ColorOpenMoji/raster.svg")
var feature_icon = preload("res://Resources/Icons/ColorOpenMoji/vector.svg")

onready var icon = get_node("RightContainer/Icon")
onready var visibility_button = get_node("RightContainer/VisibilityBox/VisibilityButton")
onready var color_tag = get_node("RightContainer/VisibilityBox/ColorRect")
onready var edit_button = get_node("LeftContainer/Edit")
onready var edit_window = get_node("EditWindow")


func _ready():
#	if layer.type == layer.types.raster:
#		icon.texture = raster_icon
#	elif layer.type == layer.types.feature:
#		icon.texture = feature_icon
	edit_button.connect("pressed", self, "_pop_edit")
	edit_window.connect("change_color_tag", self, "_change_color_tag")
	visibility_button.connect("toggled", self, "_layer_change_visibility")


func _pop_edit():
	edit_window.popup()


func _change_color_tag(color: Color):
	color_tag.color = color


func _layer_change_visibility(is_hidden: bool):
	layer.is_visible = !is_hidden
