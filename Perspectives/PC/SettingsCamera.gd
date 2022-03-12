extends Camera

#
# Automatically applies available settings such as view distance and FOV to the camera.
# The given setting_title specifies the settings directory which the camera settings to
# be used are in.
#

export(String) var setting_title
export(String) var signal_title


func _ready():
	var setting_distance = Settings.get_setting(setting_title, "view-distance")
	var setting_fov = Settings.get_setting(setting_title, "fov")
	
	if setting_distance:
		far = setting_distance
		
	if setting_fov:
		fov = setting_fov


# Display/hide a render layer.
func _toggle_render_layer(activated, layer_id):
	set_cull_mask_bit(layer_id, activated)


func _input(event):
	if event.is_action_pressed("increase_fov"):
		fov += 5
	elif event.is_action_pressed("decrease_fov"):
		fov -= 5
