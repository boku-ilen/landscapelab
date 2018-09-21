tool
extends MeshInstance

func createTerrain(dataset, img_res,  height_scale, pixel_size, splits, part):
	var origin = (Vector3(-img_res * splits/2, 0, -img_res * splits/2) + Vector3(img_res * floor(part / splits),0,img_res * (part % splits))) * pixel_size
	var arr_height = []
	
	var offset = img_res + 1 
	
	arr_height = dataset

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
	
	var height_idx = 0
	for z in range(img_res):
		for x in range(img_res):
				
			uvarray.append(Vector2(x, z)/img_res)
			varray.append(Vector3(x * pixel_size, float(arr_height[(height_idx)]/height_scale), z * pixel_size) + origin)
			uvarray.append(Vector2(x+1, z)/img_res)
			varray.append(Vector3((x+1) * pixel_size, float(arr_height[(height_idx+1)]/height_scale), z * pixel_size) + origin)
			uvarray.append(Vector2(x+1, z+1)/img_res)
			varray.append(Vector3((x+1) * pixel_size, float(arr_height[((height_idx+1)+offset)]/height_scale), (z+1) * pixel_size) + origin)

			surfTool.add_triangle_fan(varray,uvarray)
			#print(varray)
		
			uvarray.clear()
			varray.clear()
			#print("remove:")
			#print(varray)
			
			uvarray.append(Vector2(x, z)/img_res)
			varray.append(Vector3(x * pixel_size, float(arr_height[(height_idx)]/height_scale), z * pixel_size) + origin)
			uvarray.append(Vector2(x+1, z+1)/img_res)
			varray.append(Vector3((x+1) * pixel_size, float(arr_height[((height_idx+1)+offset)]/height_scale), (z+1) * pixel_size) + origin)
			uvarray.append(Vector2(x, z+1)/img_res)
			varray.append(Vector3(x * pixel_size, float(arr_height[((height_idx)+offset)]/height_scale), (z+1) * pixel_size) + origin)
			
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
	#set_mesh(mesh)
	var node = MeshInstance.new()
	var nname = "Part%d" % part
	#node.name = nname
	node.set_mesh(mesh)
	#create collider for camera control and vr teleport
	node.create_trimesh_collision()
	add_child(node)
	
	
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
	
func jsonTerrain(dict):
	return dict["Data"][0]
			
func jsonTerrainOrigin(dict):
	return dict["Metadata"]["OriginRange"]
	
func jsonTerrainPixel(dict):
	return dict["Metadata"]["PixelSize"]
	
func jsonTerrainDimensions(dict):
	return dict["Metadata"]["ArrayDimensions"]
	
	
