extends BoxContainer

# Dependency comes from the LayerRenderers-Node which should always be above in the tree
var layer: Layer

# FIXME: Get the folder (like "ModernLandscapeLab") from a global setting, like AutoTextureButton
var icon_prefix = "res://Resources/Icons/ModernLandscapeLab"

onready var icon = get_node("RightContainer/Icon")
onready var visibility_button = get_node("RightContainer/VisibilityBox/VisibilityButton")
onready var color_tag = get_node("RightContainer/VisibilityBox/ColorRect")
onready var edit_button = get_node("LeftContainer/Edit")
onready var edit_window = get_node("EditMenu")
onready var layer_name = get_node("RightContainer/Name")


func _ready():
	_reload()
	
	edit_button.connect("pressed", self, "_pop_edit")
	edit_window.connect("change_color_tag", self, "_change_color_tag")
	visibility_button.connect("toggled", self, "_layer_change_visibility")
	layer.connect("layer_changed", self, "_reload")


func _reload():
	if layer is RasterLayer:
		icon.texture = load("%s/raster.svg" % icon_prefix)
	elif layer is FeatureLayer:
		icon.texture = load("%s/vector.svg" % icon_prefix)
	else:
		match layer.render_type:
			Layer.RenderType.REALISTIC_TERRAIN:
				icon.texture = load("%s/world.svg" % icon_prefix)
			Layer.RenderType.BASIC_TERRAIN:
				icon.texture = load("%s/map.svg" % icon_prefix)
			Layer.RenderType.VEGETATION:
				icon.texture = load("%s/grass.png" % icon_prefix)
			_:
				icon.texture = load("%s/layer.svg" % icon_prefix)
	
	if layer != null:
		edit_window.layer = layer
		layer_name.text = layer.name
		color_tag.color = layer.color_tag


func _pop_edit():
	edit_window.popup(Rect2(edit_button.rect_global_position + Vector2(25, 0), Vector2(4, 4)))


func _change_color_tag(color: Color):
	color_tag.color = color


func _layer_change_visibility(is_hidden: bool):
	layer.is_visible = !is_hidden


func _draw():
	if has_focus():
		var focussed = theme.get_stylebox("FocusedBox", "BoxContainer")
		draw_style_box(focussed, Rect2(Vector2(0,0), rect_size))
