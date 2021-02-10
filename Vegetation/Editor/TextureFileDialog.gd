extends FileDialog


signal new_texture_selected(texture_path)


func _ready():
	connect("dir_selected", self, "_on_dir_selected")


func _on_dir_selected(selected_path: String):
	emit_signal("new_texture_selected", selected_path)
