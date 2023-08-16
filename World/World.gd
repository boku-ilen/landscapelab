extends Node3D


var is_fullscreen: bool = false


func _ready():
	# Initial apply of settings/configurations
	$PositionManager.terrain = get_node("Terrain")
	Screencapture.pos_manager = $PositionManager
	$Terrain/LayerRenderers.time_manager = $TimeManager
	$Terrain/LayerRenderers.weather_manager = $WeatherManager
	$WorldEnvironment.apply_datetime($TimeManager.datetime)
	_add_remote_transform($PositionManager.center_node, $WorldEnvironment/Rain, "RainRemoteTransformer")
	$WorldEnvironment/Lightning.center_node = $PositionManager.center_node
	
	# Connect signals
	$LLConfigSetup.applied_configuration.connect($PositionManager.reset_center)
	$TimeManager.datetime_changed.connect($WorldEnvironment.apply_datetime)
	$WeatherManager.visibility_changed.connect($WorldEnvironment.apply_visibility)
	$WeatherManager.cloud_coverage_changed.connect($WorldEnvironment.apply_cloud_coverage)
	$WeatherManager.cloud_density_changed.connect($WorldEnvironment.apply_cloud_density)
	$WeatherManager.wind_speed_changed.connect($WorldEnvironment.apply_wind_speed)
	$WeatherManager.wind_direction_changed.connect($WorldEnvironment.apply_wind_direction)
	$WeatherManager.rain_enabled_changed.connect($WorldEnvironment.apply_rain_enabled)
	$WeatherManager.rain_density_changed.connect($WorldEnvironment.apply_rain_density)
	$WeatherManager.rain_drop_size_changed.connect($WorldEnvironment.apply_rain_drop_size)
	$WeatherManager.lightning_frequency_changed.connect($WorldEnvironment.set_lightning_frequency)
	$WeatherManager.lightning_rotation_changed.connect($WorldEnvironment.set_lightning_rotation)
	
	$PositionManager.new_center_node.connect(func(center_node: Node3D): 
		_add_remote_transform(center_node, $WorldEnvironment/Rain, "RainRemoteTransformer"))
	$PositionManager.new_center_node.connect(func(center_node): 
		$WorldEnvironment/Lightning.center_node = center_node)
	
	$LLConfigSetup.setup()


func _input(event):
	if event.is_action_pressed("exit_fullscreen") and is_fullscreen:
		TreeHandler.switch_last_state()
		is_fullscreen = false


func _add_remote_transform(transformer: Node3D, transformed: Node3D, transformer_name: String):
	var rt: RemoteTransform3D
	if not transformer.has_node(transformer_name): 
		rt = RemoteTransform3D.new()
		rt.name = transformer_name
		rt.update_rotation = false
		rt.update_scale = false
		rt.update_position = true
		transformer.add_child(rt)
	else: 
		rt = transformer.get_node(transformer_name)
	rt.remote_path = transformed.get_path()
