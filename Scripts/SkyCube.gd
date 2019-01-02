extends Spatial

func _ready():
	# These values can be changed to achieve different weather effects
	$Worley_texture.max_distance = 0.3
	$SkyCube.get_surface_material(0).set_shader_param("cloud_density_factor", 15)
	$SkyCube.get_surface_material(0).set_shader_param("light_density_factor", 15)
	
func reposition(delta_real, delta_abs):
	$SkyCube.translation.x = delta_real.x
	$SkyCube.translation.z = delta_real.z
	
	$SkyCube.get_surface_material(0).set_shader_param("player_uv_offset", Vector3(delta_abs[0], 0, delta_abs[1]))