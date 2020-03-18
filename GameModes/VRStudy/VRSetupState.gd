extends "res://addons/gameflow/GameState.gd"


func _ready() -> void:
	get_node("Timer").connect("timeout", self, "emit_completed")
