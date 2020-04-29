extends JSONParser


var _paths: Dictionary = _parse_json("res://geodata.json")


func get_base() -> String:
	return Settings.get_setting("filesystem", "geodata-path")


func get_relative(geodata_name: String) -> String:
	return _paths[geodata_name]["name"]


func get_relative_with_ending(geodata_name: String) -> String:
	return get_relative(geodata_name) + "." + get_type(geodata_name)


func get_type(geodata_name: String) -> String:
	return _paths[geodata_name]["type"]


func get_absolute(geodata_name: String) -> String:
	return get_base().plus_file(get_relative(geodata_name))


func get_absolute_with_ending(geodata_name: String) -> String:
	return get_base().plus_file(get_relative_with_ending(geodata_name))
