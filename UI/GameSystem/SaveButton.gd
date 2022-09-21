extends Button


func _ready():
	connect("pressed",Callable(self,"_on_button_pressed"))


func _on_button_pressed():
	for goc in GameSystem.current_game_mode.game_object_collections.values():
		var gamestate_filename = OS.get_user_data_dir().path_join(goc.name + "-" +
			"gamestate-%s.shp" % [Time.get_datetime_string_from_system()]
		)
		
		if "feature_layer" in goc:
			goc.feature_layer.save_modified_layer(gamestate_filename)
