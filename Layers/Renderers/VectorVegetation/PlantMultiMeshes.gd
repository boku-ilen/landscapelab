extends RenderChunk

var height_layer: GeoRasterLayer
var plant_layer: GeoFeatureLayer

var new_multimesh

# Tree mesh data source:
# https://l4m0s.itch.io/27-vegetation-3d-assets
# TODO: Lots of duplicates at the moment - needs to be replaced with more specific plants!
var species_to_mesh = {
	"Abiesalbar": preload("res://Layers/Renderers/VectorVegetation/Pinus2.tres"),
	"Abiessprpp": preload("res://Layers/Renderers/VectorVegetation/Pinus2.tres"),
	"Acercampes": preload("res://Layers/Renderers/VectorVegetation/Quercus.tres"),
	"Acerpseudo": preload("res://Layers/Renderers/VectorVegetation/Quercus.tres"),
	"Alnusgluti": preload("res://Layers/Renderers/VectorVegetation/Quercus.tres"),
	"Alnusincan": preload("res://Layers/Renderers/VectorVegetation/Quercus.tres"),
	"Betulasprp": preload("res://Layers/Renderers/VectorVegetation/Fagus.tres"),
	"Carpinusbe": preload("res://Layers/Renderers/VectorVegetation/Fagus.tres"),
	"Castaneasa": preload("res://Layers/Renderers/VectorVegetation/Quercus.tres"),
	"Corylusave": preload("res://Layers/Renderers/VectorVegetation/Quercus.tres"),
	"Fagussylva": preload("res://Layers/Renderers/VectorVegetation/Fagus.tres"),
	"Fraxinusex": preload("res://Layers/Renderers/VectorVegetation/Fagus.tres"),
	"Fraxinusor": preload("res://Layers/Renderers/VectorVegetation/Fagus.tres"),
	"Larixdecid": preload("res://Layers/Renderers/VectorVegetation/Pinus2.tres"),
	"Piceaabies": preload("res://Layers/Renderers/VectorVegetation/Pinus.tres"),
	"Piceasitch": preload("res://Layers/Renderers/VectorVegetation/Pinus.tres"),
	"Pinuscembr": preload("res://Layers/Renderers/VectorVegetation/Pinus.tres"),
	"Pinushalep": preload("res://Layers/Renderers/VectorVegetation/Pinus.tres"),
	"Pinusmugor": preload("res://Layers/Renderers/VectorVegetation/Pinus.tres"),
	"Pinusnigra": preload("res://Layers/Renderers/VectorVegetation/Pinus.tres"),
	"Pinuspinas": preload("res://Layers/Renderers/VectorVegetation/Pinus.tres"),
	"Pinuspinea": preload("res://Layers/Renderers/VectorVegetation/Pinus.tres"),
	"Pinussylve": preload("res://Layers/Renderers/VectorVegetation/Pinus.tres"),
	"Populusnig": preload("res://Layers/Renderers/VectorVegetation/Fagus.tres"),
	"Populustre": preload("res://Layers/Renderers/VectorVegetation/Fagus.tres"),
	"Prunusaviu": preload("res://Layers/Renderers/VectorVegetation/Quercus.tres"),
	"Pseudotsug": preload("res://Layers/Renderers/VectorVegetation/Pinus.tres"),
	"Quercuscer": preload("res://Layers/Renderers/VectorVegetation/Quercus.tres"),
	"Quercusfra": preload("res://Layers/Renderers/VectorVegetation/Quercus.tres"),
	"Quercusile": preload("res://Layers/Renderers/VectorVegetation/Quercus.tres"),
	"Quercuspet": preload("res://Layers/Renderers/VectorVegetation/Quercus.tres"),
	"Quercuspub": preload("res://Layers/Renderers/VectorVegetation/Quercus.tres"),
	"Quercuspyr": preload("res://Layers/Renderers/VectorVegetation/Quercus.tres"),
	"Quercusrob": preload("res://Layers/Renderers/VectorVegetation/Quercus.tres"),
	"Quercussub": preload("res://Layers/Renderers/VectorVegetation/Quercus.tres"),
	"Robiniapse": preload("res://Layers/Renderers/VectorVegetation/Quercus.tres"),
	"Salixcapre": preload("res://Layers/Renderers/VectorVegetation/Quercus.tres"),
	"Sorbusaucu": preload("res://Layers/Renderers/VectorVegetation/Quercus.tres"),
	"Tiliasprpp": preload("res://Layers/Renderers/VectorVegetation/Fagus.tres")
}

var mesh_name_to_spritesheet_index = {
	"Fagus": 0,
	"Pinus2": 1,
	"Pinus": 1,
	"Quercus": 2
}

var species_to_mesh_name = {}
var mesh_name_to_mmi = {}

var mesh_name_to_transforms = {}
var mesh_name_to_color = {}
var mesh_name_to_custom_data = {}

var fresh_multimeshes = {}


func _ready():
	super._ready()
	
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
			add_child(mmi)


func rebuild_aabb(node):
	var aabb = AABB(global_transform.origin - position - Vector3(size / 2.0, 0.0, size / 2.0), Vector3(size, 100000, size))
	node.set_custom_aabb(aabb)


func override_build(center_x, center_y):
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
	
	var top_left_x = float(center_x - size / 2)
	var top_left_y = float(center_y + size / 2)
	
	var features = plant_layer.get_features_in_square(top_left_x, top_left_y, size, 10000000)
	
	for feature in features:
		var species = feature.get_attribute("layer")
		var mesh_name = species_to_mesh_name[species]
		var instance_scale = feature.get_attribute("height1").to_float() * 1.5
		
		# FIXME: Load these in a later refinement step
		if instance_scale < 5.0: continue

		var pos = feature.get_offset_vector3(-int(center_x), 0, -int(center_y))
		pos.y = height_layer.get_value_at_position(pos.x + center_x, center_y - pos.z)

		mesh_name_to_transforms[mesh_name].append(Transform3D()
				.scaled(Vector3(instance_scale, instance_scale, instance_scale)) \
				.rotated(Vector3.UP, PI * 0.5 * randf()) \
				.translated(pos - Vector3.UP)
		)
		mesh_name_to_custom_data[mesh_name].append(Color(
			mesh_name_to_spritesheet_index[mesh_name], # Spritesheet index
			randf(), # Randomness for shading
			0.0
		))
	
	for mesh_name in mesh_name_to_transforms.keys():
		fresh_multimeshes[mesh_name].instance_count = mesh_name_to_transforms[mesh_name].size()
		
		for i in range(mesh_name_to_transforms[mesh_name].size()):
			fresh_multimeshes[mesh_name].set_instance_transform(i, mesh_name_to_transforms[mesh_name][i])
			fresh_multimeshes[mesh_name].set_instance_custom_data(i, mesh_name_to_custom_data[mesh_name][i])


func override_apply():
	for mesh_name in fresh_multimeshes.keys():
		if fresh_multimeshes[mesh_name].instance_count > 0:
			mesh_name_to_mmi[mesh_name].visible = true
			mesh_name_to_mmi[mesh_name].multimesh = fresh_multimeshes[mesh_name].duplicate()
			rebuild_aabb(mesh_name_to_mmi[mesh_name])
		else:
			mesh_name_to_mmi[mesh_name].visible = false
