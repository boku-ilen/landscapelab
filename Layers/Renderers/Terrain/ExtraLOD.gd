extends MeshInstance3D
class_name ExtraLOD


@export var material: Material


func _ready():
	material_override = material.duplicate()


func apply_textures(heightmap, surface_heightmap, landuse):
	mesh = get_parent().get_node("Mesh").mesh
	
	if not material_override:
		logger.warn("ExtraLOD with no Material Override! This will have no effect.")
		visible = false
		return
	
	material_override.set_shader_parameter("heightmap", heightmap)
	material_override.set_shader_parameter("surface_heightmap", surface_heightmap)
	material_override.set_shader_parameter("landuse", landuse)
	material_override.set_shader_parameter("size", get_parent().size)
