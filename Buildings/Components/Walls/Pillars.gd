@tool
extends Node3D


# Needs to be set prior to build
var ground_height_at_center: float
var floors: int
const floor_height = 2.5
var height: float

var material = preload("res://Resources/Meshes/PV/Aluminum.material")

func build(footprint: Array):
	# Add "cellar" as it is required for walls, also helps at terrain with high slope
	floors += 1
	
	var instance = MultiMeshInstance3D.new()
	var mm: MultiMesh = MultiMesh.new()
	mm.set_transform_format(MultiMesh.TRANSFORM_3D)
	mm.set_instance_count(footprint.size())
	
	# Remap 2d vertices in 3d space
	footprint = footprint.map(func(vert: Vector2): 
		return Vector3(vert.x, 0, vert.y))
	
	# Instead of placing multiple "floors" of poles make one larger pole in case
	# of multiple floors
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(0.25, floors * floor_height, 0.25)
	mm.mesh = box_mesh
	
	var count = 0
	for footprint_num in footprint.size():
		var vertex: Vector3 = footprint[footprint_num]
		var vertex_after = footprint[(footprint_num + 1) % footprint.size()]
		
		# Make the poles face the appropriate direction
		var t := Transform3D(Basis.IDENTITY, vertex)
		t.basis.z = vertex.direction_to(vertex_after)
		t.basis.y = Vector3.UP
		t.basis.x = t.basis.y.cross(t.basis.z)
		
		# The polygon is winded clockwise so always going in negative direction towards next vertex
		# and then right will place it to a arguably correct place
		vertex -= t.basis.x * box_mesh.size.x / 2
		vertex += t.basis.z * box_mesh.size.z / 2
		
		t.origin = vertex + Vector3.UP * box_mesh.size.y / 2

		# Floating point inaccuracies might mess up the matrix so its sheared => orthonormalize
		t.origin = vertex + Vector3.UP * box_mesh.size.y / 2
		mm.set_instance_transform(count, t)
		
		count += 1
	
	instance.multimesh = mm
	instance.material_override = material
	call_deferred("add_child", instance)
