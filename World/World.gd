extends Spatial


var is_fullscreen: bool = false


func _ready():
	$PositionManager.terrain = get_node("Terrain")
	$PositionManager.layer_configurator = get_node("LayerConfigurator")
	
	
	$TimeManager.connect("datetime_changed", $WorldEnvironment, "apply_datetime")


func _input(event):
	if event.is_action_pressed("exit_fullscreen") and is_fullscreen:
		TreeHandler.switch_last_state()
		is_fullscreen = false
