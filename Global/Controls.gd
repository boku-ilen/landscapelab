extends Node

# Declare member variables here. Examples:
signal current_viewport
var viewport

# Called when the node enters the scene tree for the first time.
func _ready():
	connect("current_viewport", self, "_define_current_viewport")
	pass # Replace with function body.

func _define_current_viewport(viewport):
	self.viewport = viewport
	print(viewport.name)

func _input(event):
	pass
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
