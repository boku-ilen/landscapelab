extends Spatial


var is_fullscreen: bool = false


func _ready():
	$PositionManager.layer_configurator = get_node("LayerConfigurator")
	$PositionManager.terrain = get_node("Terrain")
	
	$TimeManager.connect("datetime_changed", $WorldEnvironment, "apply_datetime")
	
	$Terrain/LayerRenderers.time_manager = $TimeManager


func _input(event):
	if event.is_action_pressed("exit_fullscreen") and is_fullscreen:
		TreeHandler.switch_last_state()
		is_fullscreen = false
