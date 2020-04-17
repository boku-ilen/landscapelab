extends "res://addons/gameflow/GameState.gd"


func _ready() -> void:
	GlobalTerrain.hide_terrain()
	get_node("GuiToMesh").viewport_texture.get_node("Button").connect("pressed", self, "setup_done")


func setup_done():
	GlobalTerrain.show_terrain()
