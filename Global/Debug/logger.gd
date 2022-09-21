extends Object
class_name logger


static func categorized(message: String, category: String):
	return "[%s]: '%s'" % [message, category]


static func debug(message: String, category: String):
	print_verbose(categorized(message, category))


static func info(message: String, category: String):
	print(categorized(message, category))


static func warn(message: String, category: String):
	push_warning(categorized(message, category))


static func error(message: String, category: String):
	push_error(categorized(message, category))
