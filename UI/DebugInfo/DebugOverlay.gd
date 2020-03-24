extends Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	text = """
	FPS: %s
	Particles: %s
	Tiles: %s
	""" % [str(Engine.get_frames_per_second()), str(PerformanceTracker.number_of_particles), str(PerformanceTracker.number_of_tiles)]
