extends HBoxContainer


onready var imaging_button = get_node("ImagingButton")
onready var filimg_button = get_node("FilimgButton")
onready var clear_button = get_node("Clear")


# Called when the node enters the scene tree for the first time.
func _ready():
	imaging_button.connect("pressed", self, "_on_imaging")
	filimg_button.connect("pressed", self, "_on_filming")
	clear_button.connect("pressed",self, "_on_cleared")


# Draw the path
func _on_imaging():
	UISignal.emit_signal("imaging")


# Film on the path
func _on_filming():
	UISignal.emit_signal("toggle_imaging_view")


func _on_cleared():
	UISignal.emit_signal("clear_imaging_path")
