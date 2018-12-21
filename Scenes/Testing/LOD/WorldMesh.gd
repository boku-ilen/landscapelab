tool
extends MeshInstance

#
# This is a basic scene for any mesh which a WorldTile might hold.
# It should be instantiated as a child of a node which controls a more specific mesh via calling these functions.
# The most obvious wrapper is the TerrainMesh, which displays heightmap terrain.
# However, it can be used for any shaded plane mesh (e.g. water).
#

var mat = preload("res://Materials/HeightmapMaterial.tres")

const default_subdiv = 16

var true_subdiv
var size_without_skirt
var mesh_size

# Use a different material than the default heightmap shader - must be called before _ready()!
func set_mat(_mat):
	_mat = mat

func _ready():
	set_material_override(mat.duplicate())

# Create a PlaneMesh with a size and a modifier for the default subdiv
func set_size(size, subdiv_mod):
	var mod_subdiv = default_subdiv * subdiv_mod
	
	mesh = PlaneMesh.new()
	
	# We add 2 to subdiv and increase the size by the added squares for the skirt around the mesh (which fills gaps where things don't match up)
	size_without_skirt = size
	mesh_size = size + (2.0/(mod_subdiv + 1.0)) * size
	mesh.size = Vector2(mesh_size, mesh_size)
	
	true_subdiv = mod_subdiv + 2
	
	mesh.subdivide_depth = true_subdiv
	mesh.subdivide_width = true_subdiv

# Set any shader parameter via key and value
func set_shader_param(key, val):
	material_override.set_shader_param(key, val)