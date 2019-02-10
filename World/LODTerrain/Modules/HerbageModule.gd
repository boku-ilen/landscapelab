extends Module

#
# This module can be used for any small vegetation such as grass, flowers and herbs. It efficiently renders this using a particle shader.
# The area can be filled with multiple different plants using a distribution image.
#

var grass_scene = preload("res://World/LODTerrain/Modules/Util/Grass.tscn")

var LODS = Settings.get_setting("herbage", "rows-at-lod")

func _ready():
	# Get required herbage for this scene + textures etc
	
	if LODS.has(String(tile.lod)):
		var instance = grass_scene.instance()
		instance.name = "Herbage"
		add_child(instance)
		
		var grass = get_node("Herbage")
		
		grass.set_rows(LODS[String(tile.lod)])
		grass.set_spacing(tile.size / LODS[String(tile.lod)])

		tile.set_heightmap_params_for_obj(grass.process_material)
		tile.set_heightmap_params_for_obj(grass.material_override)
		
		grass.material_override.set_shader_param("pos", translation)