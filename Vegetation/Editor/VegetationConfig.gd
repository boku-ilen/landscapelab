extends Control


var config
var button_count = 0
var buttons_done = 0

signal done


func _ready():
	config = ConfigFile.new()
	
	# Load in the existing values
	config.load("user://vegetation_paths.cfg")
	
	for button in $PanelContainer/SelectButtons.get_children():
		if not "vegetation_variable_name" in button: continue
		
		button.connect("dir_selected", self, "_on_dir_selected", [button.vegetation_variable_name])
		button_count += 1
		
		# If this value is already known, mark the button accordingly
		if config.has_section_key("paths", button.vegetation_variable_name):
			button.set_done()
	
	$PanelContainer/SelectButtons/SaveButton.connect("pressed", self, "save_and_exit")


func save_and_exit():
	config.save("user://vegetation_paths.cfg")
	emit_signal("done")


func _on_dir_selected(dir, variable_name):
	config.set_value("paths", variable_name, dir)
	
	buttons_done += 1
	
	if button_count == buttons_done:
		save_and_exit()
