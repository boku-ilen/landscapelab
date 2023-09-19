extends Node3D


# Needs to be set prior to build
var ground_height_at_center
var floors: int
var height := 0.
var floor_height = 2.5


func build(footprint: Array):
	var mm: MultiMesh = $MultiMeshInstance3D.multimesh
	#mm.set_instance_count(footprint.size() * floors)
	
	var count = 0
	footprint = footprint.map(func(vert): 
		return Vector3(vert.x, 0, vert.y))
	
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(0.1, floor_height, 0.1)
	var footprint_size = footprint.size()
	
	for floor_num in range(floors):
		for footprint_num in footprint.size():
			var vec3: Vector3 = footprint[footprint_num]
			var vec3_before = footprint[(footprint_num - 1) % footprint.size()]
			var vec3_after = footprint[(footprint_num + 1) % footprint.size()]
			
			var shift_dir = vec3.direction_to(vec3_before) + vec3.direction_to(vec3_after)
			
			vec3.y = floor_height * floor_num + floor_height / 2
			var mesh_inst := MeshInstance3D.new()
			mesh_inst.mesh = box_mesh
			
			var t := Transform3D(Basis.IDENTITY, vec3)
			t.basis.z = vec3.direction_to(vec3_after).normalized()
			t.basis.y = Vector3.UP
			t.basis.x = t.basis.y.cross(t.basis.z)
			
			mesh_inst.transform = t.orthonormalized()
			
			add_child(mesh_inst)
			#mm.set_instance_transform(count, Transform3D(Basis.IDENTITY, vec3))
			count += 1
		height += floor_height
