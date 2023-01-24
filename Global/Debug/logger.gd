extends Object
class_name logger


static func categorized(message: String, category: String):
	return "%s - [%s]: '%s'" % [Time.get_time_string_from_system(), category, message]


static func debug(message: String, category: String):
	print_verbose(categorized(message, category))


static func info(message: String, category: String):
	print(categorized(message, category))


static func warn(message: String, category: String):
	push_warning(categorized(message, category))


static func error(message: String, category: String):
	push_error(categorized(message, category))
