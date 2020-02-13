extends Node

#
# Attach this scene to the MousePoint scene. With this an input mapped to 
# "teleport_player" will teleport the player to the cursor position in the
# World. Also the Points of Interest Menu will open.
#

var teleport_mode: bool = false
onready var cursor = get_parent().get_node("InteractRay")


func _ready():
	UISignal.connect("set_teleport_mode", self, "set_teleport_mode")
	UISignal.connect("poi_teleport", self, "_poi_teleport")


func set_teleport_mode(mode: bool):
	teleport_mode = mode


func teleport_player(coordinates: Vector3):
	PlayerInfo.update_player_pos(coordinates)


func _unhandled_input(event):
	if teleport_mode:
		if event.is_action_pressed("teleport_player"):
			teleport_player(WorldPosition.get_position_on_ground(cursor.get_collision_point()))
			GlobalSignal.emit_signal("teleported")
			get_tree().set_input_as_handled()
			set_teleport_mode(false)


func _poi_teleport(coordinates):
	teleport_player(WorldPosition.get_position_on_ground(Vector3(coordinates.x, 0, coordinates.y)))
	GlobalSignal.emit_signal("teleported")
	set_teleport_mode(false)
