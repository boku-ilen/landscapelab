extends Spatial


var is_fullscreen: bool = false


func _ready():
	$PositionManager.layer_configurator = get_node("LayerConfigurator")
	$PositionManager.terrain = get_node("Terrain")
	
	$TimeManager.connect("datetime_changed", $WorldEnvironment, "apply_datetime")
	
	$WeatherManager.connect("visibility_changed", $WorldEnvironment, "apply_visibility")
	$WeatherManager.connect("cloudiness_changed", $WorldEnvironment, "apply_cloudiness")
	$WeatherManager.connect("wind_speed_changed", $WorldEnvironment, "apply_wind_speed")
	$WeatherManager.connect("wind_direction_changed", $WorldEnvironment, "apply_wind_direction")
	$WeatherManager.connect("unshaded_changed", $WorldEnvironment, "apply_is_unshaded")
	$WeatherManager.connect("rain_enabled_changed", $WorldEnvironment, "apply_rain_enabled")
	$WeatherManager.connect("rain_density_changed", $WorldEnvironment, "apply_rain_density")
	$WeatherManager.connect("rain_drop_size_changed", $WorldEnvironment, "apply_rain_drop_size")
	
	$Terrain/LayerRenderers.time_manager = $TimeManager
	$Terrain/LayerRenderers.weather_manager = $WeatherManager
	
	Screencapture.pos_manager = $PositionManager


func _input(event):
	if event.is_action_pressed("exit_fullscreen") and is_fullscreen:
		TreeHandler.switch_last_state()
		is_fullscreen = false
