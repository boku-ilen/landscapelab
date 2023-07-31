extends Node3D
class_name MoveableObject

#
# A superclass for any movable asset (pv, windmill, etc.).
# Handles the loading of the tooltip.
#

# FIXME: Reimplement

@onready var tooltip = get_node("Tooltip3D")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
