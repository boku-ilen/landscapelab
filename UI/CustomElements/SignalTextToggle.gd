tool  # Make changes to name visible in editor
extends HBoxContainer

#
# UI element with a toggle which triggers a certain signal.
#


onready var toggle = get_node("CheckButton")
onready var name_label = get_node("Name")

export(String) var label_text setget _set_label_text, _get_label_text
export(String) var signal_to_emit
export(int) var optional_signal_parameter
export(bool) var default_toggled setget _set_default_toggled, _get_default_toggled


func _ready() -> void:
	toggle.connect("toggled", self, "_on_toggled")
	
	# It's possible that the vars couldn't be set earlier due to is_inside_tree() returning false,
	#  thus, it should definitely happen now
	name_label.text = label_text
	toggle.pressed = default_toggled


func _on_toggled(button_pressed):
	if optional_signal_parameter:
		UISignal.emit_signal(signal_to_emit, button_pressed, optional_signal_parameter)
	else:
		UISignal.emit_signal(signal_to_emit, button_pressed)


func _set_label_text(new_text: String):
	label_text = new_text
	
	if is_inside_tree():
		name_label.text = new_text


func _get_label_text():
	return label_text
	
	
func _set_default_toggled(toggled: bool):
	default_toggled = toggled
	
	if is_inside_tree():
		toggle.pressed = toggled
		
		
func _get_default_toggled():
	return default_toggled
