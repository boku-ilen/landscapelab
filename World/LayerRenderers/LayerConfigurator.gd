extends Configurator


onready var layer_renderer = preload("res://World/LayerRenderers/LayerRenderer.tscn")


func _ready():
	set_category("Layers")


func _handle_settings():
	for layer in setting_block:
		var new_renderer = layer_renderer.instance()
		new_renderer.name = "%sRenderer" % layer["name"]
