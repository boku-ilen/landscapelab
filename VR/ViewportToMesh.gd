extends MeshInstance


export(PackedScene) var viewport_element

onready var viewport = get_node("Viewport")
onready var viewport_texture = viewport_element.instance()

var material = SpatialMaterial.new()


func _ready():
	viewport.add_child(viewport_texture)
	material.albedo_texture = viewport.get_texture()
	material.flags_unshaded = true
	material.flags_transparent = true
	set_surface_material(0, material)
