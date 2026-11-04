@tool
extends Node3D
class_name BuildingBillboard

@export var quad_node: MeshInstance3D
@export var roof_quad_node: MeshInstance3D
@export var test_floors: int = 3
@export var num_floors: int
var assumedFloorHeight: float = 2.8

func construct_dummy():
	construct(test_floors, preload("res://Resources/Textures/Buildings/BillboardComponents/WindowBillboardTile.svg"), assumedFloorHeight * 4, Color.RED)

@export_tool_button("Construct DBG")
var dummy_construct: Callable = self.construct_dummy


func construct(floors: int, floor_tex: Texture2D, width: float, facade_color: Color):
	self.num_floors = floors
	
	# deep duplicate the mesh including material to set per-instance size and texture
	quad_node.mesh = quad_node.mesh.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	var mat: ShaderMaterial = quad_node.mesh.surface_get_material(0)#.duplicate()
	mat.set_shader_parameter("texture_albedo", floor_tex)
	quad_node.mesh.surface_set_material(0,mat)
	quad_node.set_instance_shader_parameter("albedo", facade_color)
	quad_node.set_instance_shader_parameter("numFloors", floors as float)
	# number of horizontal tiles is width/assumedFloorHeight because we assume that the tiling texture is square
	quad_node.set_instance_shader_parameter("numHorizontalRepeat", width / assumedFloorHeight)
	quad_node.mesh.size = Vector2(width, assumedFloorHeight * num_floors)
	quad_node.position = Vector3(0,assumedFloorHeight * num_floors * 0.5, 0)
	# for roof, shallow duplication is enough since we do not modify the material
	roof_quad_node.mesh = roof_quad_node.mesh.duplicate()
	roof_quad_node.mesh.size = Vector2(width, assumedFloorHeight * 0.5) # roof is half a floor tall; TODO set roof size from metadata
	roof_quad_node.position = Vector3(0, num_floors * assumedFloorHeight + assumedFloorHeight * 0.25, 0)