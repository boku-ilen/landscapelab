@abstract
extends GraphNodeElement
class_name ConstantValueElement


func _init()->void:
	pass

func get_input_type() -> String:
	return ""
	
@abstract
func get_output_type() -> String
	
@abstract
func create_ui(label: String) -> void

@abstract
func get_value() -> Variant

@abstract
func set_value(value: String) -> void

func get_additional_serialization_data() -> Dictionary:
	return {
		"constant_value": get_value()
	}
