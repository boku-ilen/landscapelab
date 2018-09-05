tool
extends MultiMeshInstance

var mm;

func createMultiMesh(meshPath, surface, count):
	mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = meshPath; #get_node("MeshInstance").mesh;
	mm.color_format = MultiMesh.COLOR_8BIT;
	mm.instance_count = count
	mm.set_instance_color(0, Color(1.0,0.0,0,1.0))
	mm.set_instance_color(1, Color(0.0,1.0,0,1.0))
	var mmi = MultiMeshInstance.new()
	mmi.multimesh = mm;
	add_child(mmi)
	
	# Set position of objects
	#var t = Transform();
	#t.origin = Vector3(0,6,0);
	#mm.set_instance_transform(1, t);
	
	# Set position of all objects on the surface randomly
	for i in range(mm.instance_count):
		var pos = surface[randi() % surface.size()]
		var t = Transform(Basis(), pos)
		mm.set_instance_transform(i, t)
	
	# Assign multimesh to be rendered by the MultiMeshInstance
	self.multimesh = mm
