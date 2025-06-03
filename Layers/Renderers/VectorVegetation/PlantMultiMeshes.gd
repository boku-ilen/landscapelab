extends RenderChunk

var height_layer: GeoRasterLayer
var plant_layer: GeoFeatureLayer

var features

var rng := RandomNumberGenerator.new()
var initial_rng_state

var refine_load_distance = 500

var weather_manager: WeatherManager :
	get:
		return weather_manager
	set(new_weather_manager):
		# FIXME: Seems like there's a condition where this is called once with a null
		# weather manager. Not necessarily a problem since it's called again correctly
		# later, but feels like it shouldn't be necessary.
		if not new_weather_manager:
			return
		
		weather_manager = new_weather_manager
		
		weather_manager.wind_speed_changed.connect(_apply_new_wind_speed)
		weather_manager.wind_direction_changed.connect(_apply_new_wind_direction)
		
		_apply_new_wind()

static var billboard_mesh = preload("res://Layers/Renderers/VectorVegetation/BillboardTree.tres")

# Tree mesh data source:
# https://l4m0s.itch.io/27-vegetation-3d-assets
# TODO: Lots of duplicates at the moment - needs to be replaced with more specific plants!
static var species_to_mesh = {
	"Abiesalbar": preload("res://Layers/Renderers/VectorVegetation/PinusHigh.tres"),
	"Abiessprpp": preload("res://Layers/Renderers/VectorVegetation/PinusHigh.tres"),
	"Acercampes": preload("res://Layers/Renderers/VectorVegetation/Quercus2.tres"),
	"Acerpseudo": preload("res://Layers/Renderers/VectorVegetation/Quercus2.tres"),
	"Alnusgluti": preload("res://Layers/Renderers/VectorVegetation/Quercus2.tres"),
	"Alnusincan": preload("res://Layers/Renderers/VectorVegetation/Quercus2.tres"),
	"Betulasprp": preload("res://Layers/Renderers/VectorVegetation/Betula.tres"),
	"Carpinusbe": preload("res://Layers/Renderers/VectorVegetation/Fagus.tres"),
	"Castaneasa": preload("res://Layers/Renderers/VectorVegetation/Quercus2.tres"),
	"Corylusave": preload("res://Layers/Renderers/VectorVegetation/Quercus2.tres"),
	"Fagussylva": preload("res://Layers/Renderers/VectorVegetation/Fagus.tres"),
	"Fraxinusex": preload("res://Layers/Renderers/VectorVegetation/Fraxinus.tres"),
	"Fraxinusor": preload("res://Layers/Renderers/VectorVegetation/Fraxinus.tres"),
	"Larixdecid": preload("res://Layers/Renderers/VectorVegetation/PinusHigh.tres"),
	"Piceaabies": preload("res://Layers/Renderers/VectorVegetation/Picea_abies.tres"),
	"Piceasitch": preload("res://Layers/Renderers/VectorVegetation/Picea_abies.tres"),
	"Pinuscembr": preload("res://Layers/Renderers/VectorVegetation/Pinus_sylvestris.tres"),
	"Pinushalep": preload("res://Layers/Renderers/VectorVegetation/Pinus_sylvestris.tres"),
	"Pinusmugor": preload("res://Layers/Renderers/VectorVegetation/Pinus_sylvestris.tres"),
	"Pinusnigra": preload("res://Layers/Renderers/VectorVegetation/Pinus_sylvestris.tres"),
	"Pinuspinas": preload("res://Layers/Renderers/VectorVegetation/Pinus_sylvestris.tres"),
	"Pinuspinea": preload("res://Layers/Renderers/VectorVegetation/Pinus_sylvestris.tres"),
	"Pinussylve": preload("res://Layers/Renderers/VectorVegetation/Pinus_sylvestris.tres"),
	"Populusnig": preload("res://Layers/Renderers/VectorVegetation/Fagus.tres"),
	"Populustre": preload("res://Layers/Renderers/VectorVegetation/Fagus.tres"),
	"Prunusaviu": preload("res://Layers/Renderers/VectorVegetation/Quercus2.tres"),
	"Pseudotsug": preload("res://Layers/Renderers/VectorVegetation/PinusHigh.tres"),
	"Quercuscer": preload("res://Layers/Renderers/VectorVegetation/Quercus2.tres"),
	"Quercusfra": preload("res://Layers/Renderers/VectorVegetation/Quercus2.tres"),
	"Quercusile": preload("res://Layers/Renderers/VectorVegetation/Quercus2.tres"),
	"Quercuspet": preload("res://Layers/Renderers/VectorVegetation/Quercus2.tres"),
	"Quercuspub": preload("res://Layers/Renderers/VectorVegetation/Quercus2.tres"),
	"Quercuspyr": preload("res://Layers/Renderers/VectorVegetation/Quercus2.tres"),
	"Quercusrob": preload("res://Layers/Renderers/VectorVegetation/Quercus2.tres"),
	"Quercussub": preload("res://Layers/Renderers/VectorVegetation/Quercus2.tres"),
	"Robiniapse": preload("res://Layers/Renderers/VectorVegetation/Fraxinus.tres"),
	"Salixcapre": preload("res://Layers/Renderers/VectorVegetation/Fraxinus.tres"),
	"Sorbusaucu": preload("res://Layers/Renderers/VectorVegetation/Quercus2.tres"),
	"Tiliasprpp": preload("res://Layers/Renderers/VectorVegetation/Fagus.tres"),
	"Eucalyptus": preload("res://Layers/Renderers/VectorVegetation/Eucalyptus.tres"),
	"Quercussuber": preload("res://Layers/Renderers/VectorVegetation/Quercus2.tres"),
	"Oleaeuropaea": preload("res://Layers/Renderers/VectorVegetation/Oleaeuropaea.tres")
}

static var mesh_name_to_billboard_index = {
	"PinusHigh": 0,
	"Quercus2": 1,
	"Betula": 2,
	"Fagus": 3,
	"Fraxinus": 4,
	"Picea_abies": 5,
	"Pinus_sylvestris": 6,
	"Eucalyptus": 7
}

var species_to_mesh_name = {}
var mesh_name_to_mmi = {}

var mesh_name_to_transforms = {}
var mesh_name_to_color = {}
var mesh_name_to_custom_data = {}

var fresh_multimeshes = {}

var is_detailed = false
var is_refine_load = false


func override_can_increase_quality(distance: float):
	return distance < refine_load_distance and not is_detailed


func override_increase_quality(distance: float):
	if distance < refine_load_distance and not is_detailed:
		is_detailed = true
		is_refine_load = true
		return true
	else:
		return false


func override_decrease_quality(distance: float):
	if distance > refine_load_distance and is_detailed:
		is_detailed = false
		return true
	else:
		return false


func _ready():
	super._ready()
	create_multimeshes()


func create_multimeshes():
	rng.seed = name.hash()
	initial_rng_state = rng.state
	
	species_to_mesh_name = {}
	mesh_name_to_mmi = {}

	mesh_name_to_transforms = {}
	mesh_name_to_color = {}
	mesh_name_to_custom_data = {}

	fresh_multimeshes = {}
	
	# Create MultiMeshes
	for species_string in species_to_mesh.keys():
		var mesh_name = species_to_mesh[species_string].resource_path.get_basename().get_file()
		
		species_to_mesh_name[species_string] = mesh_name
		
		if not mesh_name in mesh_name_to_mmi:
			var mmi := MultiMeshInstance3D.new()
			# Set correct layer mask so streets are not rendered onto trees
			mmi.set_layer_mask_value(1, false)
			mmi.set_layer_mask_value(3, true)
			mmi.name = mesh_name
			
			mesh_name_to_mmi[mesh_name] = mmi
			
			mmi.add_child(preload("res://addons/parentshaderupdater/PSUGatherer.tscn").instantiate())
			
			add_child(mmi)
	
	var mmi := MultiMeshInstance3D.new()
	# Set correct layer mask so streets are not rendered onto trees
	mmi.set_layer_mask_value(1, false)
	mmi.set_layer_mask_value(3, true)
	mmi.name = "Billboard"
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	mmi.add_child(preload("res://addons/parentshaderupdater/PSUGatherer.tscn").instantiate())
	
	mesh_name_to_mmi["Billboard"] = mmi
	add_child(mmi)


func rebuild_aabb(node):
	var aabb = AABB(global_transform.origin - position - Vector3(size / 2.0, 0.0, size / 2.0), Vector3(size, 100000, size))
	node.set_custom_aabb(aabb)


func override_build(center_x, center_y):
	mesh_name_to_transforms = {}
	mesh_name_to_color = {}
	mesh_name_to_custom_data = {}
	fresh_multimeshes = {}
	
	
	if is_detailed:
		for species in species_to_mesh.keys():
			var mesh_name = species_to_mesh_name[species]
			fresh_multimeshes[mesh_name] = MultiMesh.new()
			fresh_multimeshes[mesh_name].mesh = species_to_mesh[species]
			fresh_multimeshes[mesh_name].transform_format = MultiMesh.TRANSFORM_3D
			fresh_multimeshes[mesh_name].instance_count = 0
			fresh_multimeshes[mesh_name].use_custom_data = true
			
			# Done more than once, but shouldn't matter
			mesh_name_to_transforms[mesh_name] = []
			mesh_name_to_color[mesh_name] = []
			mesh_name_to_custom_data[mesh_name] = []
	else:
		var mesh_name = "Billboard"
		fresh_multimeshes[mesh_name] = MultiMesh.new()
		fresh_multimeshes[mesh_name].mesh = billboard_mesh
		fresh_multimeshes[mesh_name].transform_format = MultiMesh.TRANSFORM_3D
		fresh_multimeshes[mesh_name].instance_count = 0
		fresh_multimeshes[mesh_name].use_custom_data = true
		
		# Done more than once, but shouldn't matter
		mesh_name_to_transforms[mesh_name] = []
		mesh_name_to_color[mesh_name] = []
		mesh_name_to_custom_data[mesh_name] = []
	
	var top_left_x = float(center_x - size / 2)
	var top_left_y = float(center_y + size / 2)
	
	if not is_refine_load:
		features = plant_layer.get_features_in_square(top_left_x, top_left_y, size, 10000000)
	
	# Reset RNG to get the same random colors per feature every time
	rng.state = initial_rng_state
	
	for feature in features:
		var mesh_name
		var species_mesh_name = species_to_mesh_name[feature.get_attribute("layer")]
		
		if is_detailed:
			mesh_name = species_mesh_name
		else:
			mesh_name = "Billboard"
		
		var instance_scale = feature.get_attribute("height1").to_float() * 1.3
		
		if instance_scale < 1.0: continue
		elif instance_scale < 5.0 and not is_detailed: continue

		var pos = feature.get_offset_vector3(-int(center_x), 0, -int(center_y))
		pos.y = height_layer.get_value_at_position(pos.x + center_x, center_y - pos.z)

		mesh_name_to_transforms[mesh_name].append(Transform3D()
				.scaled(Vector3(instance_scale, instance_scale, instance_scale)) \
				.rotated(Vector3.UP, PI * 0.5 * rng.randf_range(-1.0, 1.0)) \
				.translated(pos)
		)
		
		
		if is_detailed:
			mesh_name_to_custom_data[mesh_name].append(Color(
				0.0,
				rng.randf(), # Randomness for shading
				1.0
			))
		else:
			mesh_name_to_custom_data[mesh_name].append(Color(
				mesh_name_to_billboard_index[species_mesh_name], # Spritesheet index
				rng.randf(), # Randomness for shading
				0.0
			))
	
	for mesh_name in mesh_name_to_transforms.keys():
		fresh_multimeshes[mesh_name].instance_count = mesh_name_to_transforms[mesh_name].size()
		
		for i in range(mesh_name_to_transforms[mesh_name].size()):
			fresh_multimeshes[mesh_name].set_instance_transform(i, mesh_name_to_transforms[mesh_name][i])
			fresh_multimeshes[mesh_name].set_instance_custom_data(i, mesh_name_to_custom_data[mesh_name][i])
	
	is_refine_load = false


func override_apply():
	for child in get_children():
		if child.name not in fresh_multimeshes.keys() and child.multimesh:
			child.multimesh.instance_count = 0
	
	for mesh_name in fresh_multimeshes.keys():
		if fresh_multimeshes[mesh_name].instance_count > 0:
			mesh_name_to_mmi[mesh_name].visible = true
			mesh_name_to_mmi[mesh_name].multimesh = fresh_multimeshes[mesh_name].duplicate()
			rebuild_aabb(mesh_name_to_mmi[mesh_name])
		else:
			mesh_name_to_mmi[mesh_name].visible = false


func _apply_new_wind_speed(wind_speed: float):
	_apply_new_wind()


func _apply_new_wind_direction(wind_direction: int):
	_apply_new_wind()


func _apply_new_wind():
	for mesh in species_to_mesh.values():
		for surface_id in mesh.get_surface_count():
			var material = mesh.surface_get_material(surface_id)
			
			if material is ShaderMaterial:
				var force = Vector2.UP.rotated(deg_to_rad(weather_manager.wind_direction)) * weather_manager.wind_speed
				material.set_shader_parameter("wind_speed", force)
	
