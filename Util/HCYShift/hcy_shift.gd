extends VBoxContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Vegetation.hcy_shift_changed.connect(_on_hcy_shift_changed)
	
	$Hue_SlideAndSpin.connect("value_changed", _update_hcy)
	$Chroma_SlideAndSpin.connect("value_changed", _update_hcy)
	$Y_SlideAndSpin.connect("value_changed", _update_hcy)
	
	$Cont_SlideAndSpin.connect("value_changed", _update_ces)
	$Exp_SlideAndSpin.connect("value_changed", _update_ces)
	$Sat_SlideAndSpin.connect("value_changed", _update_ces)


func _on_hcy_shift_changed(hcy_shift_vector):
	$Hue_SlideAndSpin.value = hcy_shift_vector.x
	$Chroma_SlideAndSpin.value = hcy_shift_vector.y
	$Y_SlideAndSpin.value = hcy_shift_vector.z


func _update_hcy(_new_val):
	var H = $Hue_SlideAndSpin.value
	var C = $Chroma_SlideAndSpin.value
	var Y = $Y_SlideAndSpin.value
	
	RenderingServer.global_shader_parameter_set("HCY_SHIFT", Vector3(H, C, Y))


func _update_ces(_new_val):
	var H = $Cont_SlideAndSpin.value
	var C = $Exp_SlideAndSpin.value
	var Y = $Sat_SlideAndSpin.value
	
	RenderingServer.global_shader_parameter_set("HCY_TERRAIN_SHIFT", Vector3(H, C, Y))
