extends PanelContainer


# Necessary while https://github.com/godotengine/godot/issues/86712 is not resolved
@export var panel_style: StyleBoxFlat

signal closed(successful: bool)

signal attribute_changed(reference, option_name, value)

var name_to_ref_ui := {}

var edge_buffer = 50


func popup(rect: Rect2):
	visible = true
	position = rect.position
	
	if position.x + size.x + edge_buffer > get_viewport_rect().size.x:
		position.x += get_viewport_rect().size.x - position.x - size.x - edge_buffer
	if position.y + size.y + edge_buffer > get_viewport_rect().size.y:
		position.y += get_viewport_rect().size.y - position.y - size.y - edge_buffer


func _ready():
	add_theme_stylebox_override("panel", panel_style)
	$Entries/Buttons/OKButton.pressed.connect(_on_any_button.bind(true))
	$Entries/Buttons/CancelButton.pressed.connect(_on_any_button.bind(false))


func add_configuration_option(option_name, reference, min=null, max=null):
	var vbox = VBoxContainer.new()
	vbox.name = option_name
	var label = Label.new()
	label.text = option_name
	var slider = preload("res://UI/CustomElements/SlideAndSpin.tscn").instantiate()
	slider.min_value = 1
	slider.tick_count = 10
	slider.step = 1
	if min != null:
		slider.min_value = float(min)
	if max != null:
		slider.max_value = float(max)
	
	name_to_ref_ui[option_name] = {"ref": reference, "ui": slider}
	
	slider.value_changed.connect(func(new_value):
		attribute_changed.emit(reference, option_name, new_value)
	)
	
	vbox.add_child(label)
	vbox.add_child(slider)
	$Entries/Attributes.add_child(vbox)


func add_attribute_information(attribute_name, attribute_value):
	var hbox = HBoxContainer.new()
	var label1 = Label.new()
	var label2 = Label.new()
	
	label1.text = attribute_name
	label2.text = attribute_value
	
	hbox.add_child(label1)
	hbox.add_child(label2)
	$Entries/Attributes.add_child(hbox)


func _on_any_button(confirmed := false):
	if not confirmed:
		closed.emit(false)
		queue_free()
		return
	
	for option_name in name_to_ref_ui.keys():
		var ref = name_to_ref_ui[option_name]["ref"]
		var ui = name_to_ref_ui[option_name]["ui"]
		
		# In some cases it might be necessary to set a property of 
		# a reference that is not an attribute (i.e. cluster size of a goc)
		# Otherwise store the attribute value in the mapping and emit it with the signal
		if not ref is GameObjectAttribute:
			ref.set(option_name, ui.value)
			name_to_ref_ui.erase(option_name)
		else:
			name_to_ref_ui[option_name]["val"] = var_to_str(ui.value)
	
	closed.emit(name_to_ref_ui)
	queue_free()
