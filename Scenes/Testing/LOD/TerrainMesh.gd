tool
extends Spatial

#
# This script wraps a WorldMesh to create a TerrainMesh, used for heightmap terrain.
#

var tree_scene = preload("res://Scenes/Tree.tscn")
var grass_tex = preload("res://Assets/Textures/grass-ground.jpg")

onready var mesh = get_node("Mesh")
onready var vegetation = get_node("Vegetation")
onready var col = get_node("CollisionShape")

onready var tile = get_parent().get_parent()

var trees_spawned = false

func get_height_at_position(var pos):
	var img = tile.heightmap.get_data()
	img.lock()
	var pos_scaled = (Vector2(pos.x, pos.z) - Vector2(translation.x, translation.z) + Vector2(tile.size / 2, tile.size / 2)) / tile.size
	var pix_pos = pos_scaled * img.get_size()
	var height = img.get_pixel(pix_pos.x, pix_pos.y).g * 500 # TODO: Centralize height range and use here
	img.unlock()	
	
	print(pos_scaled)
	print(pix_pos)
	print(height)
	return height

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
		if lod > 3:
			if lod > 5:
				grass.set_rows(60 / num_children)
				grass.set_spacing(size / 60 * num_children)
			elif lod > 4:
				grass.set_rows(50 / num_children)
				grass.set_spacing(size / 50 * num_children)
			else:
				grass.set_rows(40 / num_children)
				grass.set_spacing(size / 40 * num_children)
			set_params(grass.process_material, size, heightmap, texture, subdiv_mod)
			set_params(grass.material_override, size, heightmap, texture, subdiv_mod)
			
	# Plant a windmill in the middle
	if lod > 2 and not trees_spawned:
		trees_spawned = true
		
		for z in range(-tile.size/2, tile.size/2, tile.size / 3):
			for x in range(-tile.size/2, tile.size/2, 50):
				if randf() > 0.3:
					var tree = tree_scene.instance()
			
					tree.translation = Vector3(translation.x + x + (0.5 - randf()) * 50, get_height_at_position(translation), translation.z + z + (0.5 - randf()) * 50)
					add_child(tree)
	
func set_params(obj, size, heightmap, texture, subdiv_mod):
	obj.set_shader_param("tex", grass_tex) # SCREENSHOTS obj.set_shader_param("tex", texture)
	obj.set_shader_param("heightmap", heightmap)
	obj.set_shader_param("subdiv", mesh.default_subdiv * subdiv_mod)
	obj.set_shader_param("size", mesh.mesh_size)
	obj.set_shader_param("size_without_skirt", mesh.size_without_skirt)
	obj.set_shader_param("pos", transform.origin)