tool
extends MeshInstance

func createTerrain(path, size, resolution, height_scale):
	var origin = Vector3(-size/2, 0, -size/2)
	var res_size = size/resolution
	var arr_height = []
	var dataset = []
		
	#read json
	var data_file = File.new()
	if data_file.open(path, File.READ) != OK:
		return
	var data_text = data_file.get_as_text()
	data_file.close()
	var data_parse = JSON.parse(data_text)
	if typeof(data_parse.result) == TYPE_ARRAY:
		var data = data_parse.result
		dataset = data[0]
	else:
		print("error: not an array")
	#print("read data")
	#print(arr_height.size())
	
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

	var mesh = Mesh.new()
	var surfTool = SurfaceTool.new()
	var material = SpatialMaterial.new()

	surfTool.set_material(material)
	surfTool.begin(Mesh.PRIMITIVE_TRIANGLES)
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