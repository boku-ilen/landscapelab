extends VBoxContainer


var current_profile setget set_current_profile
var current_point setget set_current_point


func set_current_profile(profile):
	current_profile = profile


func set_current_point(point):
	current_point = point


func _ready():
	$RemovePointButton.connect("pressed", self, "_remove_point")


func _add_point(poly_point, drag_handler):
	if current_profile:
		var new_point = poly_point.instance()
		current_profile.add_point(new_point)
		drag_handler.dragables[new_point.name] = drag_handler.DragablePoint.new(new_point, current_profile)


func _remove_point():
	if current_point:
		current_profile.delete_point(current_point.idx)
