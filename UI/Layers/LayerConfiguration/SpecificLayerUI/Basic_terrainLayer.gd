extends SpecificLayerUI


func _ready():
	$RightBox/CheckBox.connect("toggled", self, "_toggle_color_menu")
	$RightBox/ColorShading/ButtonMin.connect("pressed", self, "_pop_color_picker",
		[$RightBox/ColorShading/ButtonMin])
	$RightBox/ColorShading/ButtonMax.connect("pressed", self, "_pop_color_picker", 
		[$RightBox/ColorShading/ButtonMax])
	# We always want the min max values of the current texture available for color
	# shading, such taht the user can see the default values


func _toggle_color_menu(toggled: bool):
	$LeftBox/ColorShading.visible = toggled
	$RightBox/ColorShading.visible = toggled
	_update_min_max()


func _update_min_max():
	var texture_layer = $RightBox/GeodataChooserTexture.get_geo_layer(true)
	
	if texture_layer != null:
		$RightBox/ColorShading/MinVal.value = texture_layer.get_min()
		$RightBox/ColorShading/MaxVal.value = texture_layer.get_max()


func _pop_color_picker(button: Button):
	var color_dialog = button.get_node("ConfirmationDialog")
	var color_picker = color_dialog.get_node("ColorPicker")
	color_dialog.connect("confirmed", self, "_set_color", [button, color_picker])
	color_dialog.popup(Rect2(button.rect_global_position, Vector2(0,0)))


func _set_color(button: Button, color_picker: ColorPicker):
	button.color = color_picker.color


func assign_specific_layer_info(layer):
	if layer.render_info == null:
		layer.render_info = Layer.BasicTerrainRenderInfo.new()
	
	var texture_layer = $RightBox/GeodataChooserTexture.get_geo_layer(true)
	var height_layer = $RightBox/GeodataChooserHeight.get_geo_layer(true)

	if !validate(texture_layer) or !validate(height_layer):
		print_warning("Texture- or height-layer is invalid!")
		return
	
	layer.render_info.height_layer = height_layer.clone()
	layer.render_info.texture_layer = texture_layer.clone()
	layer.render_info.is_color_shaded = $RightBox/CheckBox.pressed
	layer.render_info.max_value = $RightBox/ColorShading/MaxVal.value
	layer.render_info.max_color = $RightBox/ColorShading/ButtonMax.color
	layer.render_info.min_value = $RightBox/ColorShading/MinVal.value
	layer.render_info.min_color = $RightBox/ColorShading/ButtonMin.color
	layer.render_info.alpha = $RightBox/ColorShading/AlphaSpinBox.value


func init_specific_layer_info(layer):
	$RightBox/GeodataChooserHeight.init_from_layer(
		layer.render_info.height_layer)
	$RightBox/GeodataChooserTexture.init_from_layer(
		layer.render_info.texture_layer)
	$RightBox/CheckBox.pressed = layer.render_info.is_color_shaded
	
	# Information is only interesting if colorshading is enabled
	if layer.render_info.is_color_shaded:
		$RightBox/ColorShading.visible = true
		$LeftBox/ColorShading.visible = true
		$RightBox/ColorShading/MaxVal.value = layer.render_info.max_value
		$RightBox/ColorShading/ButtonMax.color = layer.render_info.max_color
		$RightBox/ColorShading/MinVal.value = layer.render_info.min_value
		$RightBox/ColorShading/ButtonMin.color = layer.render_info.min_color
		$RightBox/ColorShading/AlphaSpinBox.value = layer.render_info.alpha
