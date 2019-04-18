tool
extends Spatial


# TODO: This becomes inprecise at large offsets due to being stored in floats (which the shader requires);
# since the clouds are based on a repeating texture, we should be able to reset it seamlessly if it gets too big
var uv_offset = Vector3(0, 0, 0)


func _ready():
	# These values can be changed to achieve different weather effects
	$Worley_texture.max_distance = 0.3
	$SkyCube.get_surface_material(0).set_shader_param("cloud_density_factor", 15)
	$SkyCube.get_surface_material(0).set_shader_param("light_density_factor", 15)
	
	Offset.connect("shift_world", self, "reposition")


# Repositions the cube's UV map in order to correspond to the world/player position shifting
func reposition(delta_x, delta_z):
	uv_offset -= Vector3(delta_x, 0, delta_z)
	$SkyCube.get_surface_material(0).set_shader_param("player_uv_offset", uv_offset)


func set_sun_params(dir, energy):
	set_sun_dir(dir)
	set_sun_energy(energy)


func set_sun_dir(dir):
	$SkyCube.get_surface_material(0).set_shader_param("light_dir", dir)


func set_sun_energy(energy):
	$SkyCube.get_surface_material(0).set_shader_param("light_intensity", energy)
	print("Setting energy to ")
	print(energy)