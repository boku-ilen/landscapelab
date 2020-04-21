extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_node("MeshInstance").material_override.albedo_texture = \
			Vegetation.get_billboard_texture(
					[Vegetation.phytocoenosis_by_name["grünland intensiv"],
					Vegetation.phytocoenosis_by_name["weizen"]])
