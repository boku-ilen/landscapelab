extends "res://addons/gameflow/GameState.gd"


onready var player = get_node("Terrain/ThirdPersonPC")
onready var terrain = get_node("Terrain")


func _ready():
	terrain.x = int(Session.get_current_start_offset().x)
	terrain.z = int(Session.get_current_start_offset().y)
	terrain.center_position = player
