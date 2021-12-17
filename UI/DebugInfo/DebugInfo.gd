extends BoxContainer


export(NodePath) var layer_renderers_path
onready var layer_renderers = get_node(layer_renderers_path)

onready var logger_output = get_node("DebugPanel/DebugText")
onready var log_level_slider = get_node("ScrollContainer/Settings/VBoxContainer/Info/LogLevelInfo/LogLevelSlider")


func _ready() -> void:
	log_level_slider.connect("value_changed", self, "_on_log_level_change")
	

# Change the log level of the logger when the level slider has been moved
func _on_log_level_change(level):
	logger.set_default_output_level(level)


# Get the latest logger output and display it in the text box
func _process(delta: float) -> void:
	$DebugPanel/DebugText.text = layer_renderers.get_debug_info()
