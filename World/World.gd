extends Node3D


var is_fullscreen: bool = false


func _ready():
	$PositionManager.terrain = get_node("Terrain")
	
	$TimeManager.connect("datetime_changed",Callable($WorldEnvironment,"apply_datetime"))
	
	$WeatherManager.connect("visibility_changed",Callable($WorldEnvironment,"apply_visibility"))
	$WeatherManager.connect("cloudiness_changed",Callable($WorldEnvironment,"apply_cloudiness"))
	$WeatherManager.connect("wind_speed_changed",Callable($WorldEnvironment,"apply_wind_speed"))
	$WeatherManager.connect("wind_direction_changed",Callable($WorldEnvironment,"apply_wind_direction"))
	$WeatherManager.connect("unshaded_changed",Callable($WorldEnvironment,"apply_is_unshaded"))
	$WeatherManager.connect("rain_enabled_changed",Callable($WorldEnvironment,"apply_rain_enabled"))
	$WeatherManager.connect("rain_density_changed",Callable($WorldEnvironment,"apply_rain_density"))
	$WeatherManager.connect("rain_drop_size_changed",Callable($WorldEnvironment,"apply_rain_drop_size"))
	
	$Terrain/LayerRenderers.time_manager = $TimeManager
	$Terrain/LayerRenderers.weather_manager = $WeatherManager
	
	$WorldEnvironment/RainParticles.center_node = $PositionManager.center_node
	$PositionManager.connect("new_center_node",Callable($WorldEnvironment/RainParticles,"set_center_node"))
	$WorldEnvironment/RainSplashes.center_node = $PositionManager.center_node
	$PositionManager.connect("new_center_node",Callable($WorldEnvironment/RainSplashes,"set_center_node"))
	
	$LayerConfigurator.connect("loading_finished", $PositionManager.reset_center)
	
	Screencapture.pos_manager = $PositionManager
	
	$LayerConfigurator.setup()


func _input(event):
	if event.is_action_pressed("exit_fullscreen") and is_fullscreen:
		TreeHandler.switch_last_state()
		is_fullscreen = false
