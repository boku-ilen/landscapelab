extends ViewportContainer

# Basic minimap implementation which uses an orthographic camera placed above the player.

# Path to the player node - change accordingly!
onready var pl = get_parent().get_node("ViewportContainer/Viewport/Controller")
onready var cam = get_node("Viewport/Camera")

func _process(delta):
	# Update position
	cam.translation = pl.translation + Vector3(0, 1000, 0)
