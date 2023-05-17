extends Control
class_name RoadLaneInfo

func add_property(road_info_data: RoadInfoData) -> void:
	var property: Label = Label.new()
	property.clip_text = true
	property.text = road_info_data.property_name
	$Properties.add_child(property)
	
	var value: LineEditDraggable = LineEditDraggable.new()
	value.expand_to_text_length = true
	value.text = str(road_info_data.property_value)
	$Values.add_child(value)
	value.editable = road_info_data.editable
	
	if road_info_data.editable:
		value.text_submitted.connect(_on_any_property_changed.bind(road_info_data))


func _on_any_property_changed(new_text: String, road_info_data: RoadInfoData) -> void:
	print(new_text)
	print(road_info_data.object_to_mutate)
	print(road_info_data.variable_to_mutate)
	
	var new_value
	
	match typeof(road_info_data.property_value):
		TYPE_STRING:
			new_value = str(new_text)
		TYPE_INT:
			new_value = int(new_text) - road_info_data.property_value
		TYPE_FLOAT:
			new_value = float(new_text) - road_info_data.property_value
	
	road_info_data.object_to_mutate.set(road_info_data.variable_to_mutate, new_value)
	road_info_data.object_to_mutate.update_road_lane()
