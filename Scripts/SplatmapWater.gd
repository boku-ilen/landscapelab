tool
extends MeshInstance

export(Texture) var splatmap
export var size = 100
export var height_scale = 10

onready var shader = get_surface_material(0)

func _ready():
	shader.set_shader_param("water_map", splatmap)
	shader.set_shader_param("uv_scale", size/3)
	shader.set_shader_param("height_scale", height_scale)
	
	mesh.size = Vector2(size, size)
	mesh.subdivide_depth = size
	mesh.subdivide_width = size

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
