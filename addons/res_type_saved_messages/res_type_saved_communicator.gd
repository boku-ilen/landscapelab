@tool
extends EditorDebuggerPlugin
class_name ResTypeSavedCommunicator

var session_id: int
var session: EditorDebuggerSession
var debugtext: RichTextLabel

func _setup_session(generated_session_id: int) -> void:
	session_id = generated_session_id
	session = get_session(session_id)
	session.started.connect(func (): print("ResTypeSavedCommunicator: Session '", session_id, "' started."))
	session.stopped.connect(func (): print("ResTypeSavedCommunicator: Session '", session_id, "' stopped."))

	# Add a new tab to Debugger Session UI with text field.
	var label = Label.new()
	label.name = "ResTypeSavedCommunicator"
	label.text = "Session ID: " + var_to_str(session_id)
	debugtext = RichTextLabel.new()
	debugtext.custom_minimum_size.y = 300
	var boxcontainer := VBoxContainer.new()
	boxcontainer.name = "Resource Type Saved"
	boxcontainer.add_child(label)
	boxcontainer.add_child(debugtext)
	session.add_session_tab(boxcontainer)
	
# Called by Watcher, who has necessary infos. Data is [path, classname] of saved resource.
func message(message_string: String, data:Array[String]):
	get_session(session_id).send_message(message_string, data)
	debugtext.text += "\n- Message String: '{}'   Data: ['{}', '{}']".format(
		[message_string, data[0], data[1]], "{}"
		)
