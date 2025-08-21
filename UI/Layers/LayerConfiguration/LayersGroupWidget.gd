extends VBoxContainer


var layer_resource_group: LayerResourceGroup

@onready var layers_container = get_node("MarginContainer/Layers")
@onready var icon = get_node("VBox/RightContainer/Icon")
@onready var visibility_button = get_node("VBox/RightContainer/VisibilityBox/VisibilityButton")
@onready var color_tag = get_node("VBox/RightContainer/VisibilityBox/ColorRect")
@onready var edit_button = get_node("VBox/LeftContainer/Edit")
@onready var edit_window = get_node("VBox/EditMenu")
@onready var reload_button = get_node("VBox/LeftContainer/Reload")
@onready var layer_group_name = get_node("VBox/RightContainer/NameSizeFix/Name")


func _ready():
	_reload()
	
	
	visibility_button.toggled.connect(layer_resource_group.set_is_visible)

func _reload():
	#$VBox/RightContainer/Icon.texture = 
	
	if layer_resource_group != null:
		layer_group_name.text = layer_resource_group.name
		tooltip_text = layer_resource_group.name


func _change_color_tag(color: Color):
	color_tag.color = color


func _draw():
	if has_focus():
		var focussed = theme.get_stylebox("FocusedBox", "BoxContainer")
		draw_style_box(focussed, Rect2(Vector2(0,0), size))
