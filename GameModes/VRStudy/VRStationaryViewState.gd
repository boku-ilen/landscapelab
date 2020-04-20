extends "res://addons/gameflow/GameState.gd"


onready var timer = get_node("Timer")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# This phase has a fixed duration, so the only way it emits completed is a
	#  timer timeout
	timer.connect("timeout", self, "emit_completed")
