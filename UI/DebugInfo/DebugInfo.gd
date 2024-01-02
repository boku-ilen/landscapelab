extends BoxContainer


@export var layer_renderers_path: NodePath
@onready var layer_renderers = get_node(layer_renderers_path)

@onready var logger_output = get_node("DebugPanel/DebugText")
@onready var log_level_slider = get_node("ScrollContainer/Settings/VBoxContainer/Info/LogLevelInfo/LogLevelSlider")


func _ready() -> void:
	log_level_slider.connect("value_changed",Callable(self,"_on_log_level_change"))
	
	$ScrollContainer/Settings/VBoxContainer/MarginContainer2/Wireframes/WireframeButton.connect("toggled",Callable(self,"_switch_wireframe_mode"))


func _switch_wireframe_mode(enabled):
	get_viewport().debug_draw = SubViewport.DEBUG_DRAW_WIREFRAME if enabled else SubViewport.DEBUG_DRAW_DISABLED


# Get the latest logger output and display it in the text box
func _process(_delta: float) -> void:
	$DebugPanel/DebugText.text = layer_renderers.get_debug_info()
