tool
extends MeshInstance

onready var shader = get_surface_material(0)

func set_splatmap(map, size, height_scale):
	shader.set_shader_param("water_map", map)
	shader.set_shader_param("uv_scale", size / 10)
	shader.set_shader_param("height_scale", height_scale)
	
	mesh.size = Vector2(size, size)
	mesh.subdivide_depth = 0
	mesh.subdivide_width = 0

func _ready():
	set_splatmap(null, 10000, 0)
