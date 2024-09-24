extends VBoxContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Hue_SlideAndSpin.connect("value_changed", _update_hcy)
	$Chroma_SlideAndSpin.connect("value_changed", _update_hcy)
	$Y_SlideAndSpin.connect("value_changed", _update_hcy)


func _update_hcy(_new_val):
	var H = $Hue_SlideAndSpin.value
	var C = $Chroma_SlideAndSpin.value
	var Y = $Y_SlideAndSpin.value
	
	RenderingServer.global_shader_parameter_set("HCY_SHIFT", Vector3(H, C, Y))
