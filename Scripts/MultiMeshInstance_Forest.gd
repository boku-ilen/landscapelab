#not working yet
tool
extends MultiMeshInstance

var mm;
#var testMesh = preload("res://Objects/cube.tres")#TODO: to load from server

func createForestShape(path, size, resolution, scale):
	var origin = Vector3(-size/2, 0, -size/2)
	var res_size = size/resolution
	var dataset = []	
		
	#read json
	var data_file = File.new()#TODO: to load from server
	if data_file.open(path, File.READ) != OK:
		return
	var data_text = data_file.get_as_text()
	data_file.close()
	jsonForest(data_text, res_size, size)
	
func jsonForest(text, res_size, size):
	var scale = 100 #testing (pixelSize x res_size)
	var dict = {}
	var dataset = []
	var originRange = Vector2(567591.2158745397, 5405800.576539006)#TODO: to load from .py
	var vector = Vector2()
	var json = JSON.parse(text)
	if typeof(json.result) == TYPE_ARRAY:
		dataset = json.result[0]
	else:
		if json.error == OK:  # If parse OK
			dict = json.result
			
			#print(dict["features"].size())
			for i in range(1): # in range(dict["features"].size())
				if (dict["features"][i]["geometry"]["type"] == "Polygon"):
					#print(i+1, ": ", dict["features"][i]["geometry"]["coordinates"][0][0], "...")
					for j in dict["features"][i]["geometry"]["coordinates"][0].size():
						vector.x = dict["features"][i]["geometry"]["coordinates"][0][j][0]
						vector.y = dict["features"][i]["geometry"]["coordinates"][0][j][1]
						vector.x = (vector.x-originRange.x)/scale-size/2
						vector.y = (originRange.y-vector.y)/scale-size/2
						dataset.append(vector)
					#TODO: call function which build a shape with trees
					createShape(dataset)
					dataset = []
				
				#TODO: write similar for "MultiPolygon"
				#elif (dict["features"][i]["geometry"]["type"] == "MultiPolygon"):
				#		code
				
		else:  # If parse has errors
			print("Error: ", json.error)
			print("Error Line: ", json.error_line)
			print("Error String: ", json.error_string)
	
func createShape(dataset): #problem: ConcavePolygonShape has no size() like mesh or has_point() like Rect2 so it is not possible to check if vector is included
	var shape = ConcavePolygonShape.new() 
	#ConvexPolygonShape has currently no methods
	#ConcavePolygonShape2D.new() #has currently no methods
	var dataset3D = []
	var vector3D = Vector3()
	for i in range (dataset.size()):
		vector3D.x = dataset[i].x
		vector3D.y = 0
		vector3D.z = dataset[i].y
		dataset3D.append(vector3D)
	#print(dataset3D)
	shape.set_faces(dataset3D)
	#createMultiMeshForest(testMesh, shape, 10) #not working

func createMultiMeshForest(meshPath, surface, count):
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
		var pos = surface[randi() % surface.size()] #ConcavePolygoneShape has no size()
		var t = Transform(Basis(), pos)
		mm.set_instance_transform(i, t)
		print(pos)
	
	# Assign multimesh to be rendered by the MultiMeshInstance
	self.multimesh = mm
