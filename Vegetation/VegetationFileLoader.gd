extends Node

#
# Loads vegetation data and provides it wrapped in Godot classes with
# functionality such as generating spritesheets.
# 
# The data is expected to be laid out like this:
# vegetation-data-base-path
# 	- name1.phytocoenosis
# 		- name1.csv
# 		- billboard1.png
# 		- billboard2.png
# 	- name2.phytocoenosis
# 		- name2.csv
# ...
#


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var tex = ImageTexture.new()
	
	print(Vegetation.phytocoenosis_by_name.values()[10].plants.size())
	tex.create_from_image(Vegetation.get_billboard_sheet([Vegetation.phytocoenosis_by_name.values()[10], Vegetation.phytocoenosis_by_name.values()[11]]))
	
	get_node("MeshInstance").material_override.albedo_texture = tex
