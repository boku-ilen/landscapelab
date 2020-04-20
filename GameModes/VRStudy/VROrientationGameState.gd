extends "res://addons/gameflow/GameState.gd"


onready var timer = get_node("Timer")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GlobalTerrain.show_terrain()
	
	# If the timer times out, this phase ends, even if no selection was made
	timer.connect("timeout", self, "emit_completed")
	
	# TODO: Also connect the map selection with emit_completed - selecting a
	#  point on the mapintended way to complete this phase
