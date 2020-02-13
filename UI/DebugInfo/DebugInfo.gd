extends VBoxContainer


onready var logger_output = get_node("DebugPanel/DebugText")
onready var log_level_slider = get_node("LogLevelInfo/LogLevelSlider")


func _ready() -> void:
	visible = false
	
	UISignal.connect("debug_enable", self, "_on_debug_toggle", [true]) 
	UISignal.connect("debug_disable", self, "_on_debug_toggle", [false])
	
	log_level_slider.connect("value_changed", self, "_on_log_level_change")
	

# Change the log level of the logger when the level slider has been moved
func _on_log_level_change(level):
	logger.level = level
	

# Make this node visible or invisible when the debug mode is toggled
func _on_debug_toggle(enabled):
	visible = enabled
	

# Get the latest logger output and display it in the text box
func _process(delta: float) -> void:
	# TODO: Unnecessarily inefficient, but Godot doesn't have streams...
	#  could we make this nicer?
	logger_output.text = ""
	
	for message in logger.stream:
		if message:
			logger_output.text += message + "\n"
