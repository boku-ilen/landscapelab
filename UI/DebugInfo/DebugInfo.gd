extends BoxContainer


onready var logger_output = get_node("DebugPanel/DebugText")
onready var log_level_slider = get_node("ScrollContainer/Settings/VBoxContainer/Info/LogLevelInfo/LogLevelSlider")


func _ready() -> void:
	log_level_slider.connect("value_changed", self, "_on_log_level_change")
	

# Change the log level of the logger when the level slider has been moved
func _on_log_level_change(level):
	logger.set_default_output_level(level)


# Get the latest logger output and display it in the text box
func _process(delta: float) -> void:
	# TODO: Unnecessarily inefficient, but Godot doesn't have streams...
	#  could we make this nicer?
	logger_output.text = ""

	if visible:
		for message in logger.get_memory():
			if message:
				logger_output.text += message + "\n"
