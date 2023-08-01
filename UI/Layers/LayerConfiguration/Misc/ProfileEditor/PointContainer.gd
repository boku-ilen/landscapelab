extends VBoxContainer


var current_profile :
	get:
		return current_profile
	set(mod_value):
		mod_value

var current_point :
	get:
		return current_point
	set(mod_value):
		mod_value


func _ready():
	$RemovePointButton.connect("pressed",Callable(self,"_remove_point"))


func _add_point(poly_point, drag_handler):
	if current_profile:
		var new_point = poly_point.instantiate()
		current_profile.add_point(new_point)
		drag_handler.dragables[new_point.name] = drag_handler.DragablePoint.new(new_point, current_profile)


func _remove_point():
	if current_point:
		current_profile.delete_point(current_point.idx)
