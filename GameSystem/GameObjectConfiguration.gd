extends PanelContainer


# Necessary while https://github.com/godotengine/godot/issues/86712 is not resolved
@export var panel_style: StyleBoxFlat

@export var wait_time_before_close := 2.0
@export var grace_period_before_close := 2.0

@export var marker_distance := 90.0

signal opened
signal closed
signal delete

signal attribute_changed(reference, option_name, value)

var name_to_ref_ui := {}

var edge_buffer = 50

var last_input_time := 0


func popup(rect: Rect2):
	visible = true
	position = rect.position
	
	if position.x > get_viewport_rect().size.x / 2.0:
		# On the right
		$BrickSpace.position.x = size.x
		$DeleteSpace.position.x = size.x - marker_distance
		position.x -= size.x
	else:
		# On the left
		$BrickSpace.position.x = 0.0
		$DeleteSpace.position.x = marker_distance
	
	if position.y > get_viewport_rect().size.y / 2.0:
		# On the bottom
		$BrickSpace.position.y = size.y
		$DeleteSpace.position.y = size.y
		position.y -= size.y
		
		$Entries/SpacerTop.custom_minimum_size.y = 20.0
		$Entries/SpacerBottom.custom_minimum_size.y = 40.0
	else:
		# On the top
		$BrickSpace.position.y = 0.0
		$DeleteSpace.position.y = 0.0
		
		$Entries/SpacerTop.custom_minimum_size.y = 40.0
		$Entries/SpacerBottom.custom_minimum_size.y = 20.0
	
	opened.emit()


func close():
	visible = false
	closed.emit()


func _ready():
	add_theme_stylebox_override("panel", panel_style)
	
	attribute_changed.connect(_on_attribute_changed)


# When an attribute is changed, remember this in order to interrupt the popup from closing 
func _on_attribute_changed(reference, option_name, value):
	last_input_time = Time.get_ticks_msec()


func _input(event):
	if not is_visible_in_tree(): return
	
	if event is InputEventMouseButton and not event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			get_viewport().set_input_as_handled()
			
			# Wait for a few seconds in case new input comes
			await get_tree().create_timer(wait_time_before_close).timeout
			if last_input_time < Time.get_ticks_msec() - grace_period_before_close * 1000.0 - wait_time_before_close * 1000.0:
				close()
		else:
			if $BrickSpace.get_rect().has_point($BrickSpace.to_local(event.position)):
				# On left click (new brick placed), close immediately
				get_viewport().set_input_as_handled()
				get_parent().get_parent().popup_clicked.emit()  # FIXME: unclean
				close()
			elif $DeleteSpace.get_rect().has_point($DeleteSpace.to_local(event.position)):
				get_viewport().set_input_as_handled()
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
