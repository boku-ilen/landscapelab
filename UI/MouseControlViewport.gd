extends ViewportContainer

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	connect("mouse_entered", self, "_set_current_viewport")
	pass # Replace with function body.

func _set_current_viewport():
	Controls.emit_signal("current_viewport", self)