extends PanelContainer


# Necessary while https://github.com/godotengine/godot/issues/86712 is not resolved
@export var panel_style: StyleBoxFlat

@export var wait_time_before_close := 2.0

signal opened
signal closed
signal delete

signal attribute_changed(reference, option_name, value)

var name_to_ref_ui := {}

var edge_buffer = 50

var input_since_close_pressed := false


func popup(rect: Rect2):
	visible = true
	position = rect.position
	
	if position.x + size.x + edge_buffer > get_viewport_rect().size.x:
		position.x += get_viewport_rect().size.x - position.x - size.x - edge_buffer
	if position.y + size.y + edge_buffer > get_viewport_rect().size.y:
		position.y += get_viewport_rect().size.y - position.y - size.y - edge_buffer
	
	opened.emit()


func close():
	visible = false
	closed.emit()


func _ready():
	add_theme_stylebox_override("panel", panel_style)
	
	$BrickSpace/Area2D.input_event.connect(_on_brick_space_input_event)
	$DeleteSpace/Area2D.input_event.connect(_on_delete_space_input_event)
	
	attribute_changed.connect(_on_attribute_changed)


# When an attribute is changed, remember this in order to interrupt the popup from closing 
func _on_attribute_changed(reference, option_name, value):
	input_since_close_pressed = true


func _on_brick_space_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		viewport.set_input_as_handled()
		
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_RIGHT:
				# Wait for a few seconds in case new input comes
				input_since_close_pressed = false
				await get_tree().create_timer(wait_time_before_close).timeout
				if not input_since_close_pressed:
					close()
			elif event.button_index == MOUSE_BUTTON_MASK_LEFT:
				# On left click (new brick placed), close immediately
				get_parent().get_parent().popup_clicked.emit()  # FIXME: unclean
				close()


func _on_delete_space_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		viewport.set_input_as_handled()
		
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			delete.emit()


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


func clear_attributes():
	for child in $Entries/Attributes.get_children():
		child.free()
