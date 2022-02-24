extends AbstractRequestHandler
class_name GetSettingsRequestHandler

#
# answers to GET_SETTINGS requests which indicate a connection initialization
# of the/a LabTable which should be registered in the system
#


export(NodePath) var labtable

const LOG_MODULE := "TABLE"


# set the protocol keyword
func _init():
	protocol_keyword = "GET_SETTINGS"


func handle_request(request: Dictionary) -> Dictionary:
	
	# register the LabTable 
	if labtable:
		if labtable.has_method("register_labtable_connection"):
			labtable.register_labtable_connection()  # FIXME: method parameters?
		else:
			logger.warning("could not register LabTable - ProgrammingError!", LOG_MODULE)
			
	# answer the lab table settings
	var answer = Settings.get_setting_section("labtable")
	if answer:
		answer["success"] = true
	else:
		answer["success"] = false
	
	return answer
