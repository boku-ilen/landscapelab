extends MeshInstance


export(PackedScene) var viewport_texture

onready var viewport = get_node("Viewport")


func _ready():
	viewport.add_child(viewport_texture.instance())
	#viewport.call_deferred("add_child", viewport_texture.instance())  
	pass
