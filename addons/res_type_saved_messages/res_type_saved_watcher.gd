# EditorPlugin that detects when any resource is saved (Watcher), sends message via EditorDebuggerPlugin "session" (Communicator), which can be received at runtime in scripts.
# Used to automatically update shader via Util/ParentShaderUpdater.
#
# To implement in any listener, use the following:
#
# func _ready():
# 	EngineDebugger.register_message_capture("MessageStringFromSender", FunctionToCall)

@tool
extends EditorPlugin
class_name ResTypeSavedWatcher

var communicator: ResTypeSavedCommunicator
var debugmode: bool = false # Use this to quickly disable Output printing (Reload Plugin)

func _enter_tree() -> void:
	communicator = ResTypeSavedCommunicator.new()
	resource_saved.connect(_on_resource_saved) # Connect to EditorPlugin's Resource_Saved signal.
	add_debugger_plugin(communicator)

func _exit_tree() -> void:
	resource_saved.disconnect(_on_resource_saved) # Disconnect from EditorPlugin's Resource_Saved signal.
	remove_debugger_plugin(communicator)

# General func call on any saved resource, differentiates based on resource class
func _on_resource_saved(res) -> void:
	var resource_path: String = res.resource_path
	var resource_class: String = res.get_class()
		
	if resource_class == "Shader":
		_on_shader_saved(resource_path, resource_class) # Call func to trigger Shader specific messaging
		return
	else:
		if debugmode: print("ResTypeSavedWatcher: Saved '", resource_class, "' at '", resource_path, "' -> not a Shader. Doing nothing...")
		return

# Specific func call on Shader type resources, send message via Communicator that can then be captured by ParentShaderUpdater to trigger shader update.
func _on_shader_saved(res_path, res_class):
	communicator.message("res_shader_saved:done", [res_path, res_class])	# Colon and any string after it are required, so listener detects message correctly.
	if debugmode: print("ResTypeSavedWatcher: Saved '", res_class, "' at '", res_path, "' - messaging potential ParentShaderUpdater.")
	return
