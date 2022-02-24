extends MeshInstance


export var mesh_size: float

const LOG_MODULE := "TERRAINLAYER"


func apply_textures(heightmap, surface_heightmap, landuse):
	if not material_override:
		logger.warn("ExtraLOD with no Material Override! This will have no effect.", LOG_MODULE)
		return
	
	material_override.set_shader_param("heightmap", heightmap)
	material_override.set_shader_param("surface_heightmap", surface_heightmap)
	material_override.set_shader_param("landuse", landuse)
	material_override.set_shader_param("size", get_parent().size)
