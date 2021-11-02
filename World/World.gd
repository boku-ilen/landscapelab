extends Spatial


var is_fullscreen: bool = false


func _ready():
	$PositionManager.layer_configurator = get_node("LayerConfigurator")
	$PositionManager.terrain = get_node("Terrain")
	
	$TimeManager.connect("datetime_changed", $WorldEnvironment, "apply_datetime")
	
	$WeatherManager.connect("visibility_changed", $WorldEnvironment, "apply_visibility")
	$WeatherManager.connect("cloudiness_changed", $WorldEnvironment, "apply_cloudiness")
	$WeatherManager.connect("unshaded_changed", $WorldEnvironment, "apply_is_unshaded")
	
	$Terrain/LayerRenderers.time_manager = $TimeManager


func _input(event):
	if event.is_action_pressed("exit_fullscreen") and is_fullscreen:
		TreeHandler.switch_last_state()
		is_fullscreen = false
