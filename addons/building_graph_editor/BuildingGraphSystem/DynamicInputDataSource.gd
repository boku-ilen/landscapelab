extends NodeDataSource
class_name DynamicInputDataSource
var source: Callable

func _init(function: Callable) -> void:
	source = function
func get_value() -> Variant:
	return source.call()
