@tool
extends SubViewport
class_name PreviewMultiViewport
@export var cam: Camera3D
@export var tex: TextureRect

func _process(delta: float) -> void:
	size = tex.size
	tex.texture = self.get_viewport().get_texture()