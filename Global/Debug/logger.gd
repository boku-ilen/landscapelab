extends Object
class_name logger


static func categorized(message: String):
	var category = get_stack()[2]["source"].get_basename().get_file()
	category += "." + get_stack()[2]["function"]
	category += ":" + var_to_str(get_stack()[2]["line"])
	
	return "%s - [%s]: '%s'" % [Time.get_time_string_from_system(), category, message]


static func debug(message: String):
	print_verbose(categorized(message))


static func info(message: String):
	print(categorized(message))


static func warn(message: String):
	push_warning(categorized(message))


static func error(message: String):
	push_error(categorized(message))
