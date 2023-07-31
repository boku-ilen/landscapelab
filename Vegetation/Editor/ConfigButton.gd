extends Button


@export var vegetation_variable_name: String

signal dir_selected(dir)


# Call this when the button doesn't necessarily need to be clicked (because the data corresponding
#  to it has been set or is alredy known).
func set_done():
	add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))


func _ready():
	connect("pressed",Callable(self,"_on_button_pressed"))
	
	# Connect both, which one is emitted depends checked whether the FileDialog is set to File or Directory
	$FileDialog.connect("dir_selected",Callable(self,"_on_dir_selected"))
	$FileDialog.connect("file_selected",Callable(self,"_on_dir_selected"))


func _on_button_pressed():
	$FileDialog.popup_centered()


func _on_dir_selected(dir):
	emit_signal("dir_selected", dir)
	set_done()
