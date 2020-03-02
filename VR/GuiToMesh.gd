extends MeshInstance


export(PackedScene) var viewport_texture

onready var viewport = get_node("Viewport")


func _ready():
	viewport.add_child(viewport_texture.instance())
	var material = SpatialMaterial.new()
	var viewport_img = viewport.get_texture()
	material.albedo_texture = viewport_img
	set_surface_material(0, material)
