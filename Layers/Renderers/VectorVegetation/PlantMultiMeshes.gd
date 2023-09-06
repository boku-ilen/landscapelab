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

var species_to_mmi = {}
var species_to_transforms = {}
var fresh_multimeshes = {}


func _ready():
	super._ready()
	
	# Create MultiMeshes
	for species_string in species_to_mesh.keys():
		var mmi = MultiMeshInstance3D.new()
		mmi.name = species_string
		species_to_mmi[species_string] = mmi
		add_child(mmi)


func rebuild_aabb(node):
	var aabb = AABB(global_transform.origin - position - Vector3(size / 2.0, 0.0, size / 2.0), Vector3(size, 100000, size))
	node.set_custom_aabb(aabb)


func override_build(center_x, center_y):
	for species in species_to_mesh.keys():
		fresh_multimeshes[species] = MultiMesh.new()
		fresh_multimeshes[species].mesh = species_to_mesh[species]
		fresh_multimeshes[species].transform_format = MultiMesh.TRANSFORM_3D
		fresh_multimeshes[species].instance_count = 0
		
		species_to_transforms[species] = []
	
	var top_left_x = float(center_x - size / 2)
	var top_left_y = float(center_y + size / 2)
	
	var features = plant_layer.get_features_in_square(top_left_x, top_left_y, size, 10000000)
	
	for feature in features:
		var species = feature.get_attribute("layer")
		var instance_scale = feature.get_attribute("height").to_float() * 1.5

		var pos = feature.get_offset_vector3(-int(center_x), 0, -int(center_y))
		pos.y = height_layer.get_value_at_position(pos.x + center_x, center_y - pos.z)

		species_to_transforms[species].append(Transform3D()
				.scaled(Vector3(instance_scale, instance_scale, instance_scale)) \
				.rotated(Vector3.UP, PI * 0.25 * randf()) \
				.translated(pos - Vector3.UP)
		)
	
	for species in species_to_transforms.keys():
		fresh_multimeshes[species].instance_count = species_to_transforms[species].size()
		
		for i in range(species_to_transforms[species].size()):
			fresh_multimeshes[species].set_instance_transform(i, species_to_transforms[species][i])


func override_apply():
	for species in fresh_multimeshes.keys():
		if fresh_multimeshes[species].instance_count > 0:
			species_to_mmi[species].visible = true
			species_to_mmi[species].multimesh = fresh_multimeshes[species].duplicate()
			rebuild_aabb(species_to_mmi[species])
		else:
			species_to_mmi[species].visible = false
