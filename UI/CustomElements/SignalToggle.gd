tool  # Make changes to name visible in editor
extends HBoxContainer

#
# UI element with a toggle which triggers a certain signal.
#


onready var toggle = get_node("CheckButton")
onready var name_label = get_node("Name")

export(String) var label_text setget _set_label_text, _get_label_text
export(String) var signal_to_emit


func _ready() -> void:
	toggle.connect("toggled", self, "_on_toggled")
	
	# It's possible that the label couldn't be set earlier due to is_inside_tree() returning false,
	#  thus, it should definitely happen now
	name_label.text = label_text


func _on_toggled(button_pressed):
	GlobalSignal.emit_signal(signal_to_emit, button_pressed)


func _set_label_text(new_text: String):
	label_text = new_text
	
	if is_inside_tree():
		name_label.text = new_text


func _get_label_text():
	return label_text
