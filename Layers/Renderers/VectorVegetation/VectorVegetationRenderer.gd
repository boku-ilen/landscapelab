extends ChunkedLayerCompositionRenderer

var weather_manager: WeatherManager :
	get:
		return weather_manager 
	set(new_weather_manager):
		weather_manager = new_weather_manager


func custom_chunk_setup(chunk):
	chunk.height_layer = layer_composition.render_info.height_layer
	chunk.plant_layer = layer_composition.render_info.plant_layer
	
	chunk.weather_manager = weather_manager
