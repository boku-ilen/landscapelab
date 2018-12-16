tool
extends MeshInstance

var mat = preload("res://Materials/HeightmapMaterial.tres")
var default_subdiv = 16
var true_subdiv
var size_without_skirt
var mesh_size

func _ready():
	set_material_override(mat.duplicate())

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
	
func set_shader_param(key, val):
	material_override.set_shader_param(key, val)