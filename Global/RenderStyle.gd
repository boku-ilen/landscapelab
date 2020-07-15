extends Node


var styles = [
	Style.new("Realistic"),
	Style.new("Abstract"),
	Style.new("Table")
]


signal change_style(style)

var data_module_enabled: bool
var current_style: Style = styles[0]
var table: Spatial


func _ready():
	connect("change_style", self, "_on_change_style")
	
	# TODO: This probably has an unnecessary performance cost because it's
	#  called every time a new node is added. However, there is currently
	#  no other way to do something when a node of a certain group is added...
	get_tree().connect("node_added", self, "_check_and_set_new_node")
	
	


func _check_and_set_new_node(node: Node):
	if node.is_in_group("ClayRenderingShader"):
		update_clay_node(node, current_style)
		node.visible = !data_module_enabled
	elif node.is_in_group("DataRendering") and table != null:
		node.material_override.set_shader_param("should_clip", true)
		node.material_override.set_shader_param("table_pos", table.plate.global_transform.origin)
		node.material_override.set_shader_param("table_radius", table.plate.mesh.top_radius)
		node.visible = data_module_enabled


func _on_change_style(style: Style):
	current_style = style
	
	update_clay_renderers(style)


func update_clay_renderers(new_style):
	for node in get_tree().get_nodes_in_group("ClayRenderingShader"):
		node.visible = !data_module_enabled
		update_clay_node(node, new_style)


func update_clay_node(node, new_style):
	if new_style.name == "Realistic":
		node.material_override.set_shader_param("clay_rendering", false)
	elif new_style.name == "Abstract":
		node.material_override.set_shader_param("clay_rendering", true)
	elif new_style.name == "Table":
		assert(table)
		node.material_override.set_shader_param("should_clip", true)
		node.material_override.set_shader_param("table_pos", table.plate.global_transform.origin)
		node.material_override.set_shader_param("table_radius", table.plate.mesh.top_radius)


func update_data_shader(new_shader: Shader):
	for node in get_tree().get_nodes_in_group("DataRendering"):
		node.material_override.set_shader_param("should_clip", true)
		node.material_override.set_shader_param("table_pos", table.plate.global_transform.origin)
		node.material_override.set_shader_param("table_radius", table.plate.mesh.top_radius)
		node.visible = data_module_enabled
		#update_node_shader(node, load("res://Materials/Shaders/DataMesh.shader"))


func update_node_shader(node, new_shader):
	var shader_mat = ShaderMaterial.new()
	shader_mat.shader = new_shader
	node.material_override = shader_mat
	
	if table:
		node.material_override.set_shader_param("should_clip", true)
		node.material_override.set_shader_param("table_pos", table.plate.global_transform.origin)
		node.material_override.set_shader_param("table_radius", table.plate.mesh.top_radius)


func toggle_module():
	data_module_enabled = !data_module_enabled
	
	update_clay_renderers(Style.new("nothing"))
	update_data_shader(null)


func set_table(table):
	self.table = table
	update_clay_renderers(table)
	update_data_shader(load("res://Materials/Shaders/DataMesh.shader"))


class Style:
	var name
	
	func _init(name: String):
		self.name = name
