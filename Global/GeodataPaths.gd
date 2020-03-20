extends JSONParser


var _paths: Dictionary = _parse_json("res://geodata.json")


func get_base() -> String:
	return _paths["base-directory"]


func get_relative(geodata_name: String) -> String:
	return _paths[geodata_name]["name"]


func get_type(geodata_name: String) -> String:
	return _paths[geodata_name]["type"]


func get_absolute(geodata_name: String) -> String:
	return get_base().plus_file(get_relative(geodata_name))
