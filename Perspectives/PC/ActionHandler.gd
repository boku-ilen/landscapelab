extends Node


var cursor: RayCast
var player: AbstractPlayer

var current_mode: String

signal teleport_finished


# The string should precisely resemble a function in this script
func set_current_mode(mode: String):
	current_mode = mode


func stop_current_mode():
	current_mode = ""


# If an input comes, the player will check if the action handler has a pending
# action. If so it will call for this action. Otherwise it will handle input
# in it's usual manner.
func has_action() -> bool:
	return current_mode != ""


func action(event):
	if has_method(current_mode):
		call(current_mode, event)


func teleport(event):
	if event.is_action_pressed("teleport_player"):
		player.teleport(cursor.get_collision_point() + Vector3(0, 2, 0))
		emit_signal("teleport_finished")
