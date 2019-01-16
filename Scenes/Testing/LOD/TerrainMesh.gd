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

var trees_spawned = false

var collider_step_size : int = 10
	
func create_collision_shape(size):
#	var shape = ConcavePolygonShape.new()
#	var vecs = PoolVector3Array()
#
#	for x in range(translation.x - size/2, translation.x + size/2, collider_step_size):
#		for z in range(translation.z - size/2, translation.z + size/2, collider_step_size):
#			# calculate coordinates for triangles
#			var xLeft = x
#			var xRight = x + collider_step_size
#			var zUp = z
#			var zDown = z + collider_step_size
#			var yUpLeft = tile.get_height_at_position(Vector3(xLeft, 0, zUp))
#			var yUpRight = tile.get_height_at_position(Vector3(xRight, 0, zUp))
#			var yDownRight = tile.get_height_at_position(Vector3(xRight, 0, zDown))
#			var yDownLeft = tile.get_height_at_position(Vector3(xLeft, 0, zDown))
#
#			# add coordinates for the first triangle
#			vecs.append(Vector3(xLeft, yUpLeft, zUp))
#			vecs.append(Vector3(xRight, yUpRight, zUp))
#			vecs.append(Vector3(xRight, yDownRight, zDown))

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
		
	if lod > 4:
		col.shape = create_collision_shape(size)
			
	# Plant a windmill in the middle
#	if lod > 2 and not trees_spawned:
#		trees_spawned = true
#
#		for z in range(-tile.size/2, tile.size/2, tile.size / 3):
#			for x in range(-tile.size/2, tile.size/2, 50):
#				if randf() > 0.3:
#					var tree = tree_scene.instance()
#
#					tree.translation = Vector3(translation.x + x + (0.5 - randf()) * 50, tile.get_height_at_position(translation), translation.z + z + (0.5 - randf()) * 50)
#					add_child(tree)
	
func set_params(obj, size, heightmap, texture, subdiv_mod):
	obj.set_shader_param("tex", grass_tex) # SCREENSHOTS obj.set_shader_param("tex", texture)
	obj.set_shader_param("heightmap", heightmap)
	obj.set_shader_param("subdiv", mesh.default_subdiv * subdiv_mod)
	obj.set_shader_param("size", mesh.mesh_size)
	obj.set_shader_param("size_without_skirt", mesh.size_without_skirt)
	obj.set_shader_param("pos", transform.origin)