extends "res://addons/gameflow/GameState.gd"


export(int) var random_offset_range = 10000


func _ready() -> void:
	GlobalTerrain.hide_terrain()
	get_node("GuiToMesh").viewport_texture.get_node("Button").connect("pressed", self, "setup_done")
	
	# Add a random offset
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	var current_offset_x = Offset.x
	var current_offset_z = Offset.z
	
	var offset_addition_x = rng.randi_range(-random_offset_range, random_offset_range)
	var offset_addition_z = rng.randi_range(-random_offset_range, random_offset_range)
	
	Offset.set_offset(current_offset_x + offset_addition_x, current_offset_z + offset_addition_z)


func setup_done():
	GlobalTerrain.show_terrain()
