extends PanelContainer


onready var new_button = get_node("VBoxContainer/Menu/NewLayer")
onready var config_window = get_node("VBoxContainer/Menu/NewLayer/LayerConfig")
onready var delete_button = get_node("VBoxContainer/Menu/DeleteLayer")


func _ready():
	new_button.connect("pressed", self, "_on_new_layer")
	delete_button.connect("pressed", self, "_delete_layer")


func _on_new_layer():
	config_window.popup(new_button.get_global_rect())
