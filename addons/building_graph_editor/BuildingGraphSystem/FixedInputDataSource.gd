extends NodeDataSource
class_name FixedInputDataSource
var held_data: Variant

func _init(data: Variant) -> void:
	held_data = data
func get_value() -> Variant:
	return held_data