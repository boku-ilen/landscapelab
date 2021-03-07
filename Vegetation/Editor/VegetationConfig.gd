extends Control


var config
var button_count = 0
var buttons_done = 0

signal done


func _ready():
	for button in $PanelContainer/SelectButtons.get_children():
		button.connect("dir_selected", self, "_on_dir_selected", [button.vegetation_variable_name])
		button_count += 1
	
	config = ConfigFile.new()
	


func _on_dir_selected(dir, variable_name):
	config.set_value("paths", variable_name, dir)
	
	buttons_done += 1
	
	if button_count == buttons_done:
		config.save("user://vegetation_paths.cfg")
		emit_signal("done")
