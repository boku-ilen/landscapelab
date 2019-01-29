tool
extends Spatial

#
# This script wraps a WorldMesh to create a TerrainMesh, used for heightmap terrain.
#

var tree_scene = preload("res://Scenes/Tree.tscn")
var grass_tex = preload("res://Assets/Textures/grass-ground.jpg")

onready var mesh = get_node("Mesh")
onready var vegetation = get_node("Vegetation")
onready var col = get_node("StaticBody/CollisionShape")

onready var tile = get_parent().get_parent()

var COLLIDER_LOD = Settings.get_setting("lod", "create-collider-at-lod")
var GRASS_LODS = Settings.get_setting("grass", "rows-at-lod")
	
func create_collision_shape(size):
	var shape = ConvexPolygonShape.new()
	var vecs = PoolVector3Array()
	
	vecs.append(Vector3(size/2, tile.get_height_at_position(translation + Vector3(size/2, 0, size/2)), size/2))
	vecs.append(Vector3(-size/2, tile.get_height_at_position(translation + Vector3(-size/2, 0, size/2)), size/2))
	vecs.append(Vector3(-size/2, tile.get_height_at_position(translation + Vector3(-size/2, 0, -size/2)), -size/2))
	vecs.append(Vector3(size/2, tile.get_height_at_position(translation + Vector3(size/2, 0, -size/2)), -size/2))
			
	shape.points = vecs
	
	return shape

# Create the terrain mesh
func _ready():
	var size = tile.size
	var heightmap = tile.heightmap
	var texture = tile.texture
	var subdiv_mod = tile.subdiv_mod
	var lod = tile.lod
	
	mesh.set_size(size, subdiv_mod)
	set_params(mesh, size, heightmap, texture, subdiv_mod)
	
	var num_children = vegetation.get_children().size()
	
	for grass in vegetation.get_children():
		if GRASS_LODS.has(String(lod)):
			grass.set_rows(GRASS_LODS[String(lod)] / num_children)
			grass.set_spacing(size / GRASS_LODS[String(lod)] * num_children)

			set_params(grass.process_material, size, heightmap, texture, subdiv_mod)
			set_params(grass.material_override, size, heightmap, texture, subdiv_mod)
		
	if lod >= COLLIDER_LOD:
		col.shape = create_collision_shape(size)
	
func set_params(obj, size, heightmap, texture, subdiv_mod):
	obj.set_shader_param("tex", grass_tex) # SCREENSHOTS obj.set_shader_param("tex", texture)
	obj.set_shader_param("heightmap", heightmap)
	obj.set_shader_param("subdiv", mesh.default_subdiv * subdiv_mod)
	obj.set_shader_param("size", mesh.mesh_size)
	obj.set_shader_param("size_without_skirt", mesh.size_without_skirt)
	obj.set_shader_param("pos", transform.origin)