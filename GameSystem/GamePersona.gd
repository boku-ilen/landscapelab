extends Object
class_name GamePersona


var name: String
var icon: Resource
var description: String
var last_message: String

signal spoke(message)


func speak(message):
	spoke.emit(message)
	last_message = message
