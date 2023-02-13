extends VBoxContainer


func _ready():
	$AddField.pressed.connect(_on_add_field)


func _on_add_field():
	var hbox = HBoxContainer.new()
	hbox.add_child(LineEdit.new())
	hbox.add_child(LineEdit.new())
	
	add_child(hbox)
