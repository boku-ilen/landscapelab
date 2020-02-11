extends HBoxContainer


onready var imaging_button = get_node("ImagingButton")
onready var filimg_button = get_node("FilimgButton")


# Called when the node enters the scene tree for the first time.
func _ready():
	imaging_button.connect("pressed", self, "_on_imaging")
	filimg_button.connect("pressed", self, "_on_filming")


# Draw the path
func _on_imaging():
	UISignal.emit_signal("imaging")


# Film on the path
func _on_filming():
	UISignal.emit_signal("toggle_imaging_view")
