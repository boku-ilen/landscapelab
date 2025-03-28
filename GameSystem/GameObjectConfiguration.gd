extends PanelContainer

@export var wait_time_before_close := 2.0
@export var grace_period_before_close := 2.0

@export var marker_distance := 90.0

signal opened
signal closed
signal delete

signal attribute_changed(reference, option_name, value)

# Maps node to attribute info
# FIXME: Refactor attribute nodes to custom scene which persist this information themselves
var attribute_objects_to_game_objects = {}

var name_to_ref_ui := {}

var edge_buffer = 50

var last_input_time := 0


func popup(rect: Rect2):
	visible = true
	position = rect.position
	
	# Required to get the actual UI container size - seems to take 2 frames to calculate...
	await get_tree().process_frame
	await get_tree().process_frame
	
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


func add_configuration_class_option(option_name, reference, classes, default):
	var item_list = ItemList.new()
	item_list.fixed_column_width = 80
	item_list.icon_mode = ItemList.ICON_MODE_TOP
	item_list.max_columns = 0
	item_list.auto_height = true
	item_list.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	item_list.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	item_list.custom_minimum_size.x = (classes.keys().size() + 0.25) * item_list.fixed_column_width
	item_list.custom_minimum_size.y = item_list.fixed_column_width * 1.5
	item_list.focus_mode = Control.FOCUS_NONE
	
	var index = 0
	var default_index
	
	for class_attribute_name in classes.keys():
		item_list.add_item(class_attribute_name, preload("res://Resources/Icons/ModernLandscapeLab/circle.svg"))
		
		if class_attribute_name == default:
			default_index = index
		
		index += 1
	
	item_list.item_selected.connect(func(item_index):
		attribute_changed.emit(reference, option_name, item_list.get_item_text(item_index))
	)
	
	$Entries/Attributes/Settings.add_child(item_list)
	
	await get_tree().process_frame
	
	item_list.select(default_index)
	item_list.item_selected.emit(default_index)


func add_configuration_option(option_name, reference, min=null, max=null, default=null):
	var vbox = VBoxContainer.new()
	vbox.name = option_name
	var label = Label.new()
	label.text = option_name
	var slider = preload("res://UI/CustomElements/SlideAndSpin.tscn").instantiate()
	slider.custom_minimum_size.x = 350.0
	slider.min_value = 1
	slider.tick_count = max - min + 1 if min and max else 0
	slider.is_text_editable = false
	while slider.tick_count > 10.0: slider.tick_count /= 10.0
	slider.step = 1
	if min != null:
		slider.min_value = float(min)
	if max != null:
		slider.max_value = float(max)
	if default != null:
		slider.value = default
	
	name_to_ref_ui[option_name] = {"ref": reference, "ui": slider}
	
	slider.value_changed.connect(func(new_value):
		attribute_changed.emit(reference, option_name, new_value)
	)
	
	vbox.add_child(label)
	vbox.add_child(slider)
	$Entries/Attributes/Settings.add_child(vbox)


func reload_attribute_informations():
	for attribute_object in attribute_objects_to_game_objects.keys():
		if $Entries/Attributes/Information.has_node(attribute_object.name):
			set_attribute_value_text($Entries/Attributes/Information.get_node(attribute_object.name).get_node("Value"), attribute_object)


func set_attribute_value_text(label, attribute):
	var new_text = attribute.get_value(attribute_objects_to_game_objects[attribute])
	if new_text is float or (new_text is String and new_text.is_valid_float()):
		new_text = "%.1f" % float(new_text)
	else:
		if not new_text is String: new_text = ""
	
	if not attribute.icon_settings.is_empty():
		if attribute.icon_settings.type == "unit":
			new_text += " " + attribute.icon_settings.postfix
		elif attribute.icon_settings.type == "plus_minus":
			if new_text.to_float() > attribute.icon_settings.threshold:
				new_text = "+"
			elif new_text.to_float() < -attribute.icon_settings.threshold:
				new_text = "-"
			else:
				new_text = "0"
	
	label.text = new_text



func add_attribute_information(attribute: GameObjectAttribute, attribute_value, game_object):
	if attribute.icon_settings.is_empty() or attribute.icon_settings.type == "unit" \
			or attribute.icon_settings.type == "plus_minus":
		# Standard icon: name to value as text
		var hbox = VBoxContainer.new()
		hbox.name = attribute.name
		
		attribute_objects_to_game_objects[attribute] = game_object
		
		if attribute_value is float or float(attribute_value) > 0.0:
			attribute_value = "%.1f" % attribute_value
		
		hbox.custom_minimum_size.x = min(attribute_value.length() + attribute.name.length(), 600.0)
		
		var label1 = Label.new()
		label1.text = attribute.name
		label1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hbox.add_child(label1)
		
		var label2 = Label.new()
		label2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label2.name = "Value"
		
		# Style fixes for long text
		label2.autowrap_mode = TextServer.AUTOWRAP_WORD
		label2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		set_attribute_value_text(label2, attribute)
	
		hbox.add_child(label2)
		
		var margin = HBoxContainer.new()
		margin.custom_minimum_size.y = 30.0
		hbox.add_child(margin)
		
		$Entries/Attributes/Information.add_child(hbox)
		
		# FIXME: Required to work around https://github.com/godotengine/godot/issues/28818 in some edge cases
		await get_tree().process_frame
		await get_tree().process_frame
		size = Vector2(0, 0)
	else:
		# Special icon
		if attribute.icon_settings.type == "outlined":
			# Icon with outline which is colored based on threshold values
			if not $Entries/Attributes/Information.has_node("OutlinedIcons"):
				var hbox = HBoxContainer.new()
				hbox.name = "OutlinedIcons"
				$Entries/Attributes/Information.add_child(hbox)
			
			var icon = load(attribute.icon_settings.icon)
			var color
			for threshold in attribute.icon_settings.color_thresholds.keys():
				if attribute_value <= str_to_var(threshold):
					color = attribute.icon_settings.color_thresholds[threshold]
					break
			
			var icon_node = preload("res://UI/CustomElements/OutlinedTexture.tscn").instantiate()
			icon_node.texture = icon
			icon_node.outline_color = Color(color)
			
			$Entries/Attributes/Information/OutlinedIcons.add_child(icon_node)
		elif attribute.icon_settings.type == "show_if_exceeds":
			# Icon which only shows up if the attribute value exceeds a certain threshold
			if not $Entries/Attributes/Information.has_node("OutlinedIcons"):
				var hbox = HBoxContainer.new()
				hbox.name = "OutlinedIcons"
				$Entries/Attributes/Information.add_child(hbox)
			if attribute_value >= attribute.icon_settings.threshold:
				var icon = load(attribute.icon_settings.icon)
				var icon_node = preload("res://UI/CustomElements/MarginTexture.tscn").instantiate()
				icon_node.texture = icon
				$Entries/Attributes/Information/OutlinedIcons.add_child(icon_node)


func clear_attributes():
	attribute_objects_to_game_objects.clear()
	
	for child in $Entries/Attributes/Information.get_children():
		child.free()
	
	for child in $Entries/Attributes/Settings.get_children():
		child.free()
