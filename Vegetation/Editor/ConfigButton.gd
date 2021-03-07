extends Button


export(String) var vegetation_variable_name

signal dir_selected(dir)


func _ready():
	connect("pressed", self, "_on_button_pressed")
	
	# Connect both, which one is emitted depends on whether the FileDialog is set to File or Directory
	$FileDialog.connect("dir_selected", self, "_on_dir_selected")
	$FileDialog.connect("file_selected", self, "_on_dir_selected")


func _on_button_pressed():
	$FileDialog.popup_centered()


func _on_dir_selected(dir):
	emit_signal("dir_selected", dir)
	visible = false
