extends Node

#
# Attach this scene to the MousePoint scene. With this an input mapped to 
# "teleport_player" will teleport the player to the cursor position in the
# World. Also the Points of Interest Menu will open.
#

var teleport_mode: bool = false
onready var cursor = get_parent().get_node("InteractRay")


func _ready():
	GlobalSignal.connect("teleport", self, "_set_teleport_mode")
	GlobalSignal.connect("poi_teleport", self, "_poi_teleport")


func _unhandled_input(event):
	if teleport_mode:
		if event.is_action_pressed("teleport_player"):
			_teleport_player()
			GlobalSignal.emit_signal("teleported")
			teleport_mode = false
			get_tree().set_input_as_handled()

func _set_teleport_mode():
	teleport_mode = true


func _teleport_player():
	PlayerInfo.update_player_pos(WorldPosition.get_position_on_ground(cursor.get_collision_point()))


func _poi_teleport(coordinates):
	PlayerInfo.update_player_pos(WorldPosition.get_position_on_ground(Vector3(coordinates.x, 0, coordinates.y)))
	GlobalSignal.emit_signal("teleported")
	teleport_mode = false
