extends Spatial

#
# Attach this scene to MousePoint.tscn. 
# Once the setting_path bool is enabled, with the mapped inputs of "imaging_set_path" and
# "imaging_set_focus" a path and a focussed point can be set.
#

onready var cursor: RayCast = get_parent().get_node("InteractRay")

var currently_imaging: bool = false


func _input(event):
	if event.is_action_pressed("imaging"):
		_switch_imaging_mode()
	elif currently_imaging:
		
		if event.is_action_pressed("imaging_set_path"):
			var position = WorldPosition.get_position_on_ground(cursor.get_collision_point())
			GlobalSignal.emit_signal("imaging_add_path_point", position)
		elif event.is_action_pressed("imaging_set_focus"):
			var position = WorldPosition.get_position_on_ground(cursor.get_collision_point())
			GlobalSignal.emit_signal("imaging_set_focus", position)
	
	#get_tree().set_input_as_handled()


func _switch_imaging_mode():
	currently_imaging = !currently_imaging
