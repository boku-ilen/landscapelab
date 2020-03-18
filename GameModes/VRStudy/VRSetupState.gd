extends "res://addons/gameflow/GameState.gd"


func _ready() -> void:
	GlobalTerrain.hide_terrain()
	get_node("Timer").connect("timeout", self, "setup_done")


func setup_done():
	GlobalTerrain.show_terrain()
	emit_completed()
