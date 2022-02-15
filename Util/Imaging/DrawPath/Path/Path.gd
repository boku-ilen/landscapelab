extends "res://Util/Imaging/InterpolateLinear.gd"


# As we do not want to have the line directly on the ground there will be a 
# placeholder value

onready var dolly_cam: Camera = $Path/PathFollow/ViewportContainer/RecordingViewport/DollyCamera
onready var path = $Path


func add_path_point(position):
	var all_points = $Path.curve.get_baked_points()
	
	if not all_points.empty():
		var last_point = $Path.curve.get_point_position($Path.curve.get_point_count() - 1)

		var possible_interpolated: Array = interpolate_points(
			last_point, position)
		for point in possible_interpolated:
			$Path.curve.add_point(point)
	else:
		$Path.curve.add_point(position)


func set_focus_position(position_on_ground, path_height):
	$Focus.set_translation(position_on_ground)
	$Focus/Sprite3D.set_translation(path_height)
	dolly_cam.focus = $Focus


func clear():
	$Path.get_curve().clear_points()


func set_imaging_visible(is_visible: bool):
	if is_visible:
		$Path/PathFollow/ViewportContainer.set_visible(true)
	else:
		$Path/PathFollow/ViewportContainer.set_visible(false)


func toggle_cam(is_enabled: bool):
	dolly_cam.toggle_cam(is_enabled)
	if is_enabled:
		$Path/PathFollow.offset = 0.01
	else:
		$Path/PathFollow.unit_offset = 0.0
