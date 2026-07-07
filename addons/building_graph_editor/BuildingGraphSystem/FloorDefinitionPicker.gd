@tool
extends EditorResourcePicker
class_name FloorDefinitionPicker

func get_allowed_types() -> PackedStringArray:
	return PackedStringArray(["FloorDefinition"])
	