extends Node3D


# As we do not want to have the line directly checked the ground there will be a 
# placeholder value

@onready var dolly_cam := $DollyRail/PathFollow3D/DollyCamera
@onready var path = $DollyRail.curve
@onready var focus_path = $FocusPath.curve : 
	set(new_path):
		path = new_path
		$DollyRail.curve = path
		toggle_cam(true)


func _ready():
	$DollyRail.curve_changed.connect(func(): toggle_cam(path.point_count > 0))


func clear():
	$FocusPath/PathFollow3D/Focus.visible = false
	$DollyRail.get_curve().clear_points()
	$FocusPath.get_curve().clear_points()


func toggle_cam(is_enabled: bool):
	dolly_cam.toggle_cam(is_enabled)
	if is_enabled:
		$DollyRail/PathFollow3D.progress = 0.01
	else:
		$DollyRail/PathFollow3D.progress_ratio = 0.0
