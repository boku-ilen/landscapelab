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
	

	var mat: ShaderMaterial = quad_node.get_active_material(0).duplicate()
	mat.set_shader_parameter("texture_albedo", floor_tex)
	mat.set_shader_parameter("albedo", facade_color)
	mat.set_shader_parameter("numFloors", floors as float)
	mat.set_shader_parameter("numHorizontalRepeat", width / assumedFloorHeight)
	quad_node.mesh.surface_set_material(0,mat)
	quad_node.mesh.size = Vector2(width, assumedFloorHeight * num_floors)
	quad_node.position = Vector3(0,assumedFloorHeight * num_floors * 0.5, 0)
	roof_quad_node.mesh.size = Vector2(width, assumedFloorHeight * 0.5)
	roof_quad_node.position = Vector3(0, num_floors * assumedFloorHeight + assumedFloorHeight * 0.25, 0)