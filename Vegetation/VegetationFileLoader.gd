extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var tex = ImageTexture.new()
	
	print(Vegetation.phytocoenosis_by_name.values()[10].plants.size())
	tex.create_from_image(Vegetation.get_billboard_sheet([Vegetation.phytocoenosis_by_name.values()[10], Vegetation.phytocoenosis_by_name.values()[11]]))
	
	get_node("MeshInstance").material_override.albedo_texture = tex
