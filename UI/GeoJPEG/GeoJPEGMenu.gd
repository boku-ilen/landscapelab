extends VBoxContainer


func _ready():
	if not $PythonWrapper.has_python_node():
		$Heading.text = "Cannot access Python! It is required for this tool."
		$FileOpenButton.disabled = true
	
	$FileOpenButton/FileDialog.connect("file_selected", self, "_on_file_selected")


func _on_file_selected(filepath):
	var exif_reader = $PythonWrapper.get_python_node()
	
	if exif_reader:
		exif_reader.open(filepath)
		print(exif_reader.get_coordinates())
