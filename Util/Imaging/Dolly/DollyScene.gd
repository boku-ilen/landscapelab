extends Spatial


# As we do not want to have the line directly on the ground there will be a 
# placeholder value

var dolly_cam: Camera setget set_cam
onready var path = $DollyRail


func set_cam(cam):
	dolly_cam = cam
	dolly_cam.path_follow = $DollyRail/PathFollow


func add_path_point(position):
	var all_points = $DollyRail.curve.get_baked_points()
	
	$DollyRail.curve.add_point(position)


func set_focus_position(position_on_ground, path_height):
	$Focus.visible = true
	$Focus.set_translation(position_on_ground)
	$Focus/Sprite3D.set_translation(path_height)
	dolly_cam.focus = $Focus


func clear():
	$Focus.visible = false
	$DollyRail.get_curve().clear_points()


func toggle_cam(is_enabled: bool):
	dolly_cam.toggle_cam(is_enabled)
	if is_enabled:
		$DollyRail/PathFollow.offset = 0.01
	else:
		$DollyRail/PathFollow.unit_offset = 0.0
