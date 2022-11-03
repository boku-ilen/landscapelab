extends SpecificLayerCompositionUI


func _ready():
	$RightBox/CheckBox.connect("toggled",Callable(self,"_toggle_color_menu"))
	$RightBox/ColorShading/ButtonMin.connect("pressed", Callable(self, "_pop_color_picker")
		.bind($RightBox/ColorShading/ButtonMin))
	$RightBox/ColorShading/ButtonMax.connect("pressed", Callable(self, "_pop_color_picker") 
		.bind($RightBox/ColorShading/ButtonMax))
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
	color_dialog.connect("confirmed",Callable(self,"_set_color").bind(button, color_picker))
	color_dialog.popup(Rect2(button.global_position, Vector2(0,0)))


func _set_color(button: Button, color_picker: ColorPicker):
	button.color = color_picker.color


func assign_specific_layer_info(layerc):
	if layerc.render_info == null:
		layerc.render_info = LayerComposition.BasicTerrainRenderInfo.new()
	
	var texture_layer = $RightBox/GeodataChooserTexture.get_geo_layer(true)
	var height_layer = $RightBox/GeodataChooserHeight.get_geo_layer(true)

	if !validate(texture_layer) or !validate(height_layer):
		print_warning("Texture2D- or height-layer is invalid!")
		return
	
	layerc.render_info.height_layer = height_layer.clone()
	layerc.render_info.texture_layer = texture_layer.clone()
	layerc.render_info.is_color_shaded = $RightBox/CheckBox.pressed
	layerc.render_info.max_value = $RightBox/ColorShading/MaxVal.value
	layerc.render_info.max_color = $RightBox/ColorShading/ButtonMax.color
	layerc.render_info.min_value = $RightBox/ColorShading/MinVal.value
	layerc.render_info.min_color = $RightBox/ColorShading/ButtonMin.color
	layerc.render_info.alpha = $RightBox/ColorShading/AlphaSpinBox.value


func init_specific_layer_info(layerc):
	$RightBox/GeodataChooserHeight.init_from_layer(
		layerc.render_info.height_layer)
	$RightBox/GeodataChooserTexture.init_from_layer(
		layerc.render_info.texture_layer)
	$RightBox/CheckBox.button_pressed = layerc.render_info.is_color_shaded
	
	# Information is only interesting if colorshading is enabled
	if layerc.render_info.is_color_shaded:
		$RightBox/ColorShading.visible = true
		$LeftBox/ColorShading.visible = true
		$RightBox/ColorShading/MaxVal.value = layerc.render_info.max_value
		$RightBox/ColorShading/ButtonMax.color = layerc.render_info.max_color
		$RightBox/ColorShading/MinVal.value = layerc.render_info.min_value
		$RightBox/ColorShading/ButtonMin.color = layerc.render_info.min_color
		$RightBox/ColorShading/AlphaSpinBox.value = layerc.render_info.alpha
