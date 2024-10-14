extends LayerCompositionRenderer


var renderers
var offset = Vector3.ZERO


var weather_manager: WeatherManager :
	get:
		return weather_manager
	set(new_weather_manager):
		weather_manager = new_weather_manager

		weather_manager.connect("wind_speed_changed",Callable(self,"_on_wind_speed_changed"))
		_on_wind_speed_changed(weather_manager.wind_speed)


func _ready():
	super._ready()
	renderers = Vegetation.get_renderers()
	add_child(renderers)
	_on_wind_speed_changed(weather_manager.wind_speed)
	
	Vegetation.new_data.connect(full_load)


func _on_wind_speed_changed(new_wind_speed):
	if renderers:
		for renderer in renderers.get_children():
			renderer.apply_wind_speed(new_wind_speed)


# Called when the node enters the scene tree for the first time.
func full_load():
	for renderer in renderers.get_children():
		renderer.complete_update(layer_composition.render_info.height_layer, layer_composition.render_info.landuse_layer,
				center[0], center[1], 0.0, 0.0, 0.0, 0.0)


func is_new_loading_required(position_diff: Vector3) -> bool:
	# Small radius for grass?
	if Vector2(position_diff.x, position_diff.z).length_squared() >= 100:
		return true
	
	return false


func adapt_load(_diff: Vector3):
	super.adapt_load(_diff)
	
	# Clamp to steps of 1 in order to maintain the land-use grid
	# FIXME: actually depends on the resolution of the land-use and potentially other factors
	var clamped_pos_x = position_manager.center_node.position.x - fposmod(position_manager.center_node.position.x, 2.0)
	var clamped_pos_y = position_manager.center_node.position.z + (2.0 - fposmod(position_manager.center_node.position.z, 2.0))
	
	var world_position = [
		center[0] + clamped_pos_x,
		center[1] - clamped_pos_y
	]
	
	var uv_offset_x = clamped_pos_x
	var uv_offset_y = clamped_pos_y
	
	for renderer in renderers.get_children():
		renderer.complete_update(layer_composition.render_info.height_layer, layer_composition.render_info.landuse_layer,
				world_position[0], world_position[1], uv_offset_x, uv_offset_y, clamped_pos_x, clamped_pos_y)
	
	call_deferred("apply_new_data")


func _process(delta):
	super._process(delta)
	
	# Continuously reposition the Vegetation particles in the most optimal way
	for renderer in renderers.get_children():
		renderer.position = Vector3(
			position_manager.center_node.position.x,
			0.0,
			position_manager.center_node.position.z
		)
		
#		# Follow camera forward in order to only render in front
#		renderer.position += position_manager.center_node.get_look_direction() * (renderer.spacing * renderer.rows * 0.5)
		
		renderer.position = Vector3(
			renderer.position.x - fposmod(renderer.position.x, renderer.spacing * (1.0 + (float(renderer.density_class.id == 6) * 2.0))),
			0.0,
			renderer.position.z - fposmod(renderer.position.z, renderer.spacing)
		)
		
		renderer.process_material.set_shader_parameter(
			"view_direction",
			position_manager.center_node.get_look_direction()
		)
		
		renderer.restart()


func apply_new_data():
	for renderer in renderers.get_children():
		renderer.apply_textures()
	
	logger.info("Applied full new RasterVegetationRenderer data for %s" % [name])


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
