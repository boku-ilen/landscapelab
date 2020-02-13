extends MeshInstance


# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func set_sun_energy(new_energy: float):
	get_surface_material(0).set_shader_param("sun_energy", new_energy)


func set_sun_direction(new_direction: Vector3):
	get_surface_material(0).set_shader_param("sun_direction", new_direction)
