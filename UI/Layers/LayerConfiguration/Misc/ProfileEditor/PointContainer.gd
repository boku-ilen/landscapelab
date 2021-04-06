extends VBoxContainer


var current_profile setget set_current_profile
var current_point setget set_current_point


func _ready():
	$RemovePointButton.connect("pressed", self, "_remove_point")


func set_current_profile(profile):
	current_profile = profile


func set_current_point(point):
	current_point = point


func _add_point(current_profile, poly_point):
	if current_profile:
		current_profile.add_point(poly_point.instance())


func _remove_point(current_profile, current_point):
	if current_point:
		current_profile.delete_point(current_point.idx)
