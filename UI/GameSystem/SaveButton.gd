extends Button


func _ready():
	connect("pressed", self, "_on_button_pressed")


func _on_button_pressed():
	for goc in GameSystem.current_game_mode.game_object_collections.values():
		var timestamp = OS.get_datetime()
		var gamestate_filename = OS.get_user_data_dir().plus_file(goc.name + "-" +
			"gamestate-%d%d%d-%d%d%d-%d.shp" % [timestamp["year"], timestamp["month"],
				timestamp["day"], timestamp["hour"], timestamp["minute"], timestamp["second"], 0]
		)
		
		if "feature_layer" in goc:
			goc.feature_layer.save_modified_layer(gamestate_filename)
