extends MeshInstance


export var mesh_size: float


func apply_size(size):
	scale.x = size / mesh_size
	scale.z = size / mesh_size


func apply_textures(heightmap, surface_heightmap, landuse):
	if not material_override:
		logger.warn("ExtraLOD with no Material Override! This will have no effect.")
		return
	
	material_override.set_shader_param("heightmap", heightmap)
	material_override.set_shader_param("surface_heightmap", surface_heightmap)
	material_override.set_shader_param("landuse", landuse)
