extends Button


func _ready():
	connect("pressed", self, "_start_file_select")


func _start_file_select():
	$TextureFileDialog.popup()
