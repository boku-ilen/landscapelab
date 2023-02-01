extends Node


var styles = [
	Style.new("Realistic"),
	Style.new("Simple"),
	Style.new("Abstract")
]


signal change_style(style)

var current_style: Style = styles[0]


func _ready():
	connect("change_style",Callable(self,"_on_change_style"))
	
	# TODO: This probably has an unnecessary performance cost because it's
	#  called every time a new node is added. However, there is currently
	#  no other way to do something when a node of a certain group is added...
	get_tree().connect("node_added",Callable(self,"_check_and_set_new_node"))


func _check_and_set_new_node(node: Node):
	if node.is_in_group("ClayRenderingShader"):
		update_clay_node(node, current_style)


func _on_change_style(style: Style):
	current_style = style
	
	update_clay_renderers(style)


func update_clay_renderers(new_style):
	for node in get_tree().get_nodes_in_group("ClayRenderingShader"):
		update_clay_node(node, new_style)


func update_clay_node(node, new_style):
	if new_style.name == "Realistic":
		node.material_override.set_shader_parameter("clay_rendering", false)
		node.material_override.set_shader_parameter("simple_rendering", false)
	elif new_style.name == "Abstract":
		node.material_override.set_shader_parameter("clay_rendering", true)
		node.material_override.set_shader_parameter("simple_rendering", false)
	elif new_style.name == "Simple":
		node.material_override.set_shader_parameter("simple_rendering", true)


class Style:
	var name
	
	func _init(initial_name: String):
		self.name = initial_name
