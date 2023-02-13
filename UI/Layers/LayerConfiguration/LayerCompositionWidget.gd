extends BoxContainer

# Dependency comes from the LayerRenderers-Node which should always be above in the tree
var layer_composition: LayerComposition

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
	
	edit_button.connect("pressed",Callable(self,"_pop_edit"))
	reload_button.connect("pressed",Callable(self,"_on_layer_reload_pressed"))
	edit_window.connect("change_color_tag",Callable(self,"_change_color_tag"))
	edit_window.connect("translate_to_layer",Callable(self,"_emit_translate_to_layer"))
	visibility_button.connect("toggled",Callable(self,"_layer_change_visibility"))
	layer_composition.connect("layer_changed",Callable(self,"_reload"))
	$GeoLayers.connect(
		"item_collapsed", 
		func(treeitem: TreeItem): 
			if treeitem.is_any_collapsed(): $GeoLayers.set_custom_minimum_size(Vector2i(0, 8))
			else: $GeoLayers.set_custom_minimum_size(Vector2i(0, 80)))

func _reload():
	icon.texture = layer_composition.render_info.icon
	
	if layer_composition != null:
		edit_window.layer_composition = layer_composition
		layer_name.text = layer_composition.name
		tooltip_text = layer_composition.name
		color_tag.color = layer_composition.color_tag
		
		# Visualize the geo layers the composition is composed of as tree
		var tree = $GeoLayers
		var root: TreeItem = tree.create_item()
		root.set_selectable(0, false)
	
		var described_geolayers: Dictionary = layer_composition.render_info.get_described_geolayers()
		for geo_layer_decription in described_geolayers:
			var tree_item: TreeItem = tree.create_item(root)
			var geo_layer = described_geolayers[geo_layer_decription]
			tree_item.set_text(0, "%s: %s" % 
				[geo_layer_decription, geo_layer.resource_name])
			tree_item.set_metadata(0, geo_layer)
			
		root.set_collapsed(true)


func _pop_edit():
	edit_window.popup(Rect2(edit_button.global_position + Vector2(25, 0), Vector2(4, 4)))


func _on_layer_reload_pressed():
	layer_composition.emit_signal("refresh_view")


func _change_color_tag(color: Color):
	color_tag.color = color


func _layer_change_visibility(is_hidden: bool):
	layer_composition.is_visible = !is_hidden


func _emit_translate_to_layer():
	var center_avg := Vector3.ZERO
	var count := 0
	for geolayer in layer_composition.render_info.get_geolayers():
		center_avg += geolayer.get_center()
		count += 1
	
	center_avg /= count

	emit_signal("translate_to_layer", center_avg.x, center_avg.z)


func _draw():
	if has_focus():
		var focussed = theme.get_stylebox("FocusedBox", "BoxContainer")
		draw_style_box(focussed, Rect2(Vector2(0,0), size))
