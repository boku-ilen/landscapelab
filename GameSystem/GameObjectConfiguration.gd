extends ConfirmationDialog


# Necessary while https://github.com/godotengine/godot/issues/86712 is not resolved
@export var panel_style: StyleBoxFlat

signal closed(successful: bool)

var name_to_ref_ui := {} 


func _ready():
	add_theme_stylebox_override("panel", panel_style)
	confirmed.connect(_on_any_button.bind(true))
	canceled.connect(_on_any_button.bind(false))


func add_configuration_option(option_name, reference):
	var vbox = VBoxContainer.new()
	vbox.name = option_name
	var label = Label.new()
	label.text = option_name
	var slider = preload("res://UI/CustomElements/SlideAndSpin.tscn").instantiate()
	slider.min_value = 1
	slider.tick_count = 10
	slider.step = 1
	
	name_to_ref_ui[option_name] = {"ref": reference, "ui": slider}
	
	vbox.add_child(label)
	vbox.add_child(slider)
	$VBoxContainer.add_child(vbox)


func _on_any_button(confirmed := false):
	if not confirmed:
		closed.emit(false)
		queue_free()
		return
	
	for option_name in name_to_ref_ui:
		var ref = name_to_ref_ui[option_name]["ref"]
		var ui = name_to_ref_ui[option_name]["ui"]
		
		# In some cases it might be necessary to set a property of 
		# a reference that is not an attribute (i.e. cluster size of a goc)
		if ref is GameObjectAttribute:
			ref.set_value(ui.value)
		else: 
			ref.set(option_name, ui.value)
	
	closed.emit(true)
	queue_free()
