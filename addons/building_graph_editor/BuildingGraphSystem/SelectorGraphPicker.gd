@tool
extends EditorResourcePicker
class_name SelectorGraphPicker

func get_allowed_types() -> PackedStringArray:
	return PackedStringArray(["JSON"])