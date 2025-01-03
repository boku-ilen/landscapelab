extends BoxContainer

# Dependency comes from the LayerRenderers-Node which should always be above in the tree
var layer_definition: LayerDefinition

# FIXME: Get the folder (like "ModernLandscapeLab") from a global setting, like AutoTextureButton
var icon_prefix = "res://Resources/Icons/ModernLandscapeLab"

@onready var icon = get_node("VBox/RightContainer/Icon")
@onready var visibility_button = get_node("VBox/RightContainer/VisibilityBox/VisibilityButton")
@onready var color_tag = get_node("VBox/RightContainer/VisibilityBox/ColorRect")
@onready var edit_button = get_node("VBox/LeftContainer/Edit")
@onready var edit_window = get_node("VBox/EditMenu")
@onready var reload_button = get_node("VBox/LeftContainer/Reload")
@onready var layer_name = get_node("VBox/RightContainer/NameSizeFix/Name")


signal translate_to_layer(x, z)


func _ready():
	_reload()
	
	layer_definition.connect("layer_changed",Callable(self,"_reload"))


func _reload():
	icon.texture = layer_definition.ui_info.icon
	
	if layer_definition != null:
		layer_name.text = layer_definition.name
		tooltip_text = layer_definition.name


func _pop_edit():
	edit_window.popup(Rect2(edit_button.global_position + Vector2(25, 0), Vector2(4, 4)))


func _on_layer_reload_pressed():
	layer_definition.emit_signal("refresh_view")


func _change_color_tag(color: Color):
	color_tag.color = color


func _layer_change_visibility(is_hidden: bool):
	layer_definition.is_visible = !is_hidden


func _draw():
	if has_focus():
		var focussed = theme.get_stylebox("FocusedBox", "BoxContainer")
		draw_style_box(focussed, Rect2(Vector2(0,0), size))
