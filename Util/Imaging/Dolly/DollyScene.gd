extends Node3D


# As we do not want to have the line directly checked the ground there will be a 
# placeholder value

var dolly_cam: Camera3D :
	get:
		return dolly_cam
	set(cam):
		dolly_cam = cam
		dolly_cam.path_follow = $DollyRail/PathFollow3D


@onready var path = $DollyRail.curve


func set_focus_position(position_on_ground, path_height):
	$Focus.visible = true
	$Focus.set_position(position_on_ground)
	$Focus/Sprite3D.set_position(path_height)
	dolly_cam.focus = $Focus


func clear():
	$Focus.visible = false
	$DollyRail.get_curve().clear_points()


func toggle_cam(is_enabled: bool):
	dolly_cam.toggle_cam(is_enabled)
	if is_enabled:
		$DollyRail/PathFollow3D.progress = 0.01
	else:
		$DollyRail/PathFollow3D.progress_ratio = 0.0
