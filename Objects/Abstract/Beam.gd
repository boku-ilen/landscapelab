@tool
extends Node3D


@export var color: Color


func _ready():
	$MeshInstance3D.material_override.albedo_color = color
