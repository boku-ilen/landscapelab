extends LayerCompositionRenderer


var renderers
var offset = Vector3.ZERO
var position_last_frame := Vector3.ZERO

var done_applying := true
var load_position := Vector3.ZERO


var weather_manager: WeatherManager :
	get:
		return weather_manager
	set(new_weather_manager):
		weather_manager = new_weather_manager

		weather_manager.connect("wind_speed_changed", func(new_speed):
			_on_wind_changed(weather_manager.wind_speed, weather_manager.wind_direction)
		)
		
		
		weather_manager.connect("wind_direction_changed", func(new_direction):
			_on_wind_changed(weather_manager.wind_speed, weather_manager.wind_direction)
		)
		_on_wind_changed(weather_manager.wind_speed, weather_manager.wind_direction)


func _ready():
	super._ready()
	renderers = Vegetation.get_renderers()
	add_child(renderers)
	_on_wind_changed(weather_manager.wind_speed, weather_manager.wind_direction)
	
	Vegetation.new_data.connect(full_load)


func _on_wind_changed(new_wind_speed, new_wind_direction):
	if renderers:
		for renderer in renderers.get_children():
			var force = Vector2.UP.rotated(deg_to_rad(new_wind_direction)) * new_wind_speed
			renderer.apply_wind(force)


# Called when the node enters the scene tree for the first time.
func full_load():
	for renderer in renderers.get_children():
		renderer.complete_update(layer_composition.render_info.height_layer, layer_composition.render_info.landuse_layer,
				center, Vector3(0.0, 0.0, 0.0))


func is_new_loading_required(position_diff: Vector3) -> bool:
	# Small radius for grass?
	if Vector2(position_diff.x, position_diff.z).length_squared() >= 20 and done_applying:
		return true
	
	return false


func adapt_load(_diff: Vector3):
	super.adapt_load(_diff)
	
	# Stop loading new data until applying this load is finished
	done_applying = false
	
	load_position =  position_manager.center_node.position
	
	for renderer in renderers.get_children():
		renderer.complete_update(layer_composition.render_info.height_layer, layer_composition.render_info.landuse_layer,
				center, position_manager.center_node.position)
	
	call_deferred("apply_new_data")


func apply_new_data():
	for renderer in renderers.get_children():
		renderer.apply_textures()
		
		# Continuously reposition the Vegetation particles in the most optimal way
		renderer.position = Vector3(
			load_position.x,
			0.0,
			load_position.z
		)
		
		renderer.position = Vector3(
			renderer.position.x - fposmod(renderer.position.x, renderer.spacing * (1.0 + (float(renderer.density_class.id == 6) * 2.0))),
			0.0,
			renderer.position.z - fposmod(renderer.position.z, renderer.spacing)
		)
	
	logger.info("Applied full new RasterVegetationRenderer data for %s" % [name])
	
	# Make sure to wait until the LIDOverlay viewport is finished until we set done_applying to true
	#  (check the `await`s in VegetationParticles.gd)
	await get_tree().process_frame
	await get_tree().process_frame
	
	done_applying = true


func get_debug_info() -> String:
	var total_emitted_particles = 0
	var active_renderers = 0
	var total_renderers = 0

	if get_child_count() > 0:
		for renderer in get_child(0).get_children():
			if renderer.visible:
				total_emitted_particles += renderer.rows * renderer.rows
				active_renderers += 1

			total_renderers += 1

	return "{0} of {1} renderers active.\n{2} plants emitted.".format([
		active_renderers,
		total_renderers,
		total_emitted_particles
	])
