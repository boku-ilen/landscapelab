extends VRGuiElement


onready var button = get_node("Button")
onready var label = get_node("Label")
onready var toggler = get_node("Control")

# Called when the node enters the scene tree for the first time.
func _ready():
	button.connect("toggled", self, "_pressed")


func _pressed(toggle):
	label.text = "Button pressed: " + String(toggle) + "\n Toggle-button: " + String(toggler.is_pressed())
