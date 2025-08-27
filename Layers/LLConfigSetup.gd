extends Configurator

var has_loaded = false

signal applied_configuration


func _ready():
	category = "geodata"


func setup():
	var path = get_setting("config-path")

	if path == null:
		logger.info("No configuration path was set.")
	else:
		load_ll_json(path)


func load_ll_json(path: String):
	var ll_file_access = LLFileAccess.open(path)
	if ll_file_access == null:
		logger.error("Could not load config at " + path)
		return
	
	ll_file_access.apply(Vegetation, Layers, Scenarios, GameSystem)

	has_loaded = true
	applied_configuration.emit()


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_V and event.is_pressed():
			var path = get_setting("config-path")
			var ll_file_access = LLFileAccess.open(path)
			ll_file_access.apply_vegetation(Vegetation)
