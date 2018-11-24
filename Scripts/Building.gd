extends "EnvironmentalObject.gd"

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

var buildingData = {'id':-1, 'coordinates': [], 'floors': 0}
export var floor_height = 10;

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass

func init(bData):
	buildingData = bData
	
	var surfTool = SurfaceTool.new()
	var material = SpatialMaterial.new()
	
	material.flags_unshaded = false
	
	surfTool.begin(Mesh.PRIMITIVE_TRIANGLES)
	surfTool.set_material(material)
	
	var mean = Vector3(0,0,0)
	var b_points = [[],[]]
	for p in bData['coordinates'][0]:
		b_points[0].append(p - Vector3(0,floor_height, 0) - buildingData['coordinates'][0][0])
		b_points[1].append(p + Vector3(0,floor_height * bData['floors'], 0) - buildingData['coordinates'][0][0])
		mean += p - buildingData['coordinates'][0][0]
	
	if bData['coordinates'][0].size() > 0:
		mean /= bData['coordinates'][0].size()
	mean += Vector3(0,floor_height * 1.5, 0)
	
	for e in range(1, b_points[0].size()):
		#wall lower right
		surfTool.add_vertex(b_points[0][e])
		#surfTool.add_uv(Vector2(0,1))
		surfTool.add_vertex(b_points[1][e - 1])
		#surfTool.add_uv(Vector2(1,0))
		surfTool.add_vertex(b_points[0][e - 1])
		#surfTool.add_uv(Vector2(1,1))
		
		#wall upper left
		surfTool.add_vertex(b_points[0][e])
		#surfTool.add_uv(Vector2(0,1))
		surfTool.add_vertex(b_points[1][e])
		#surfTool.add_uv(Vector2(0,0))
		surfTool.add_vertex(b_points[1][e - 1])
		#surfTool.add_uv(Vector2(1,0))
		
		#roof
		surfTool.add_vertex(mean)
		#surfTool.add_uv(Vector2(0.5,0))
		surfTool.add_vertex(b_points[1][e - 1])
		#surfTool.add_uv(Vector2(1,1))
		surfTool.add_vertex(b_points[1][e])
		#surfTool.add_uv(Vector2(0,1))
	
	surfTool.generate_normals()
	var mesh = surfTool.commit()
	get_child(0).mesh = mesh
	
	translate(buildingData['coordinates'][0][0])
	update_position()

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
