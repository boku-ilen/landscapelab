extends Node3D


# Needs to be set prior to build
var ground_height_at_center
var height
var floors: int :
	set(new_floors):
		floors = new_floors
		height = floor_height * new_floors
var floor_height = 2.5


func build(footprint: Array):
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.set_instance_count(footprint.size() * floors)
	
	# Remap 2d vertices in 3d space
	footprint = footprint.map(func(vert): 
		return Vector3(vert.x, 0, vert.y))
	
	# Instead of placing multiple "floors" of poles make one larger pole in case
	# of multiple floors
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(0.1, floors * floor_height, 0.1)
	$MultiMeshInstance3D.material_override.uv1_scale = Vector3(0.1, floors * floor_height, 0.1)
	mm.mesh = box_mesh
	
	var count = 0
	for footprint_num in footprint.size():
		var vertex: Vector3 = footprint[footprint_num]
		var vertex_after = footprint[(footprint_num + 1) % footprint.size()]
		
		# Box meshes are centered so we need to add half of the meshes size
		# + small offset to prevent gaps from orthonormalizing
		vertex.y = box_mesh.size.y / 2 + 0.02
		
		# Make the poles face the appropriate direction
		var t := Transform3D(Basis.IDENTITY, Vector3.ZERO)
		t.basis.z = vertex.direction_to(vertex_after).normalized()
		t.basis.y = Vector3.UP
		t.basis.x = t.basis.y.cross(t.basis.z)
		
		# The polygon is winded clockwise so always going in negative direction towards next vertex
		# and then right will place it to a arguably correct place
		vertex -= t.basis.x * box_mesh.size.x / 2
		vertex += t.basis.z * box_mesh.size.z / 2
		t.origin = vertex
		
		# Floating point inaccuracies might mess up the matrix so its sheared => orthonormalize
		mm.set_instance_transform(count, t.orthonormalized())
		count += 1
	
	$MultiMeshInstance3D.multimesh = mm

