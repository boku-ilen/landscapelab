extends Node
class_name ShiftingHandler

#
# To allow for infinite worlds without floating point errors, the world is
# shifted if the player goes too far. Many nodes need to react to this shifting
# and reposition themselves. Such nodes are put in groups which signify the
# type of reaction they need to take to shifting.
# Implementations of this ShiftingHandler should implement _handle_shift for
# their specific group, which implements how a single node in their group
# shifts.
#

export(String) var group_name


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Offset.connect("shift_world", self, "_on_shift_world")


# Implement with this group's shifting behavior.
func _handle_shift(node: Node, delta_x : int, delta_z : int):
	pass


func _on_shift_world(delta_x : int, delta_z : int):
	for node in _get_nodes():
		_handle_shift(node, delta_x, delta_z)


func _get_nodes():
	return get_tree().get_nodes_in_group(group_name)
