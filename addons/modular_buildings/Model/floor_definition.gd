@tool
extends Resource
class_name FloorDefinition

@export var walls: Array[WallTileDefinition]
@export var door: Mesh
@export var corner_90: Mesh
# A minimal element to fill where other assets do not fit
@export var spacer_block: Mesh
@export var height := 3.


func _init(_walls = walls, _door = door, _corner_90 = corner_90, _spacer_block = spacer_block, _height:=3.) -> void:
	door = _door
	corner_90 = _corner_90
	walls = _walls
	spacer_block = _spacer_block
	height = _height
