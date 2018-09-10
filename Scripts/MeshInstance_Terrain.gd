tool
extends MeshInstance

func createTerrain(dataset, size, resolution, height_scale):
	var origin = Vector3(-size/2, 0, -size/2)
	var res_size = size/resolution
	var arr_height = []
		
	var offset = size + 1 
	if (res_size != 1):
		offset = (offset-1) / res_size + 1
		var dim = size + 1
		var multipleDim = res_size * dim
		for i in range(dataset.size()):
			if (i % res_size == 0 && i % multipleDim < dim):
				arr_height.append(dataset[i])
		#print(arr_height)		
	else:
		arr_height = dataset
		#print(arr_height)

	var mesh = Mesh.new()
	var surfTool = SurfaceTool.new()
	var material = SpatialMaterial.new()
	
	#TODO: to load from server (should also work with jpg/png)
	#material.flags_unshaded = true;
	#material.albedo_texture = load("res://Images/ortofoto.tres")
	
	surfTool.begin(Mesh.PRIMITIVE_TRIANGLES)
	surfTool.set_material(material)

	surfTool.add_smooth_group(true)
	surfTool.add_color(Color(1, 0, 0, 1))

	var uvarray = []
	var varray = []
	uvarray.clear()
	varray.clear()
	var i = 0
	var height_idx = 0
	for z in range(resolution):
		for x in range(resolution):
				
			uvarray.append(Vector2(x, z)/resolution)
			varray.append(Vector3(x*res_size, float(arr_height[(height_idx)]/height_scale), z*res_size) + origin)
			uvarray.append(Vector2(x+1, z)/resolution)
			varray.append(Vector3((x+1)*res_size, float(arr_height[(height_idx+1)]/height_scale), z*res_size) + origin)
			uvarray.append(Vector2(x+1, z+1)/resolution)
			varray.append(Vector3((x+1)*res_size, float(arr_height[((height_idx+1)+offset)]/height_scale), (z+1)*res_size) + origin)

			surfTool.add_triangle_fan(varray,uvarray)
			#print(varray)
		
			uvarray.clear()
			varray.clear()
			#print("remove:")
			#print(varray)
			
			uvarray.append(Vector2(x, z)/resolution)
			varray.append(Vector3(x*res_size, float(arr_height[(height_idx)]/height_scale), z*res_size) + origin)
			uvarray.append(Vector2(x+1, z+1)/resolution)
			varray.append(Vector3((x+1)*res_size, float(arr_height[((height_idx+1)+offset)]/height_scale), (z+1)*res_size) + origin)
			uvarray.append(Vector2(x, z+1)/resolution)
			varray.append(Vector3(x*res_size, float(arr_height[((height_idx)+offset)]/height_scale), (z+1)*res_size) + origin)
			
			surfTool.add_triangle_fan(varray,uvarray)
			#print(varray)
		
			uvarray.clear()
			varray.clear()
			#print("remove:")
			#print(varray)
			height_idx = height_idx + 1
		height_idx = height_idx + 1
		#print("height_idx:")
		#print(height_idx)

	surfTool.generate_normals()
	surfTool.index()
	surfTool.commit(mesh)	
	set_mesh(mesh)
	
	return(mesh)
	
func get_terrain(mesh):
	var tool = MeshDataTool.new()
	var meshPosition = []
	tool.create_from_surface(mesh, 0)

	for i in range(0, tool.get_vertex_count()):
		var position = tool.get_vertex(i)		
		meshPosition.append(position)
		
    #Should be the tool deleted?
	#tool.free() #attempted to free a reference
	
	return meshPosition
	
func jsonTerrain(text):
	var dict = {}
	var dataset = []
	var json = JSON.parse(text)
	if typeof(json.result) == TYPE_ARRAY:
		dataset = json.result[0]
	else:
		if json.error == OK:  # If parse OK
			dict = json.result
			if dict.keys()[0] == "Data":
				dataset = (dict.values()[0])[0]
		else:  # If parse has errors
			print("Error: ", json.error)
			print("Error Line: ", json.error_line)
			print("Error String: ", json.error_string)
	return dataset
	
