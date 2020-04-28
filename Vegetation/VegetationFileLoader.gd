extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Just for testing Vegetation spritesheet functionality
	get_node("MeshInstance").material_override.albedo_texture = \
			Vegetation.get_billboard_texture(
					[Vegetation.phytocoenosis_by_name["grünland intensiv"],
					Vegetation.phytocoenosis_by_name["weizen"]])
