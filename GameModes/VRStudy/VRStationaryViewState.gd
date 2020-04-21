extends "res://addons/gameflow/GameState.gd"


onready var timer = get_node("Timer")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# This phase has a fixed duration, so the only way it emits completed is a
	#  timer timeout
	timer.connect("timeout", self, "done")
	
	for i in range(100):
		print("Last state")
	
	# Start tracking
	GlobalSignal.emit_signal("tracking_start", "freelook")


func done():
	GlobalSignal.emit_signal("tracking_stop")
	emit_completed()
