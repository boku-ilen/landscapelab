@tool
extends Resource
class_name WallTileDefinition

@export var model: Mesh
@export_range(0.0,1.0,0.05) var probability: float
@export var may_repeat: bool
@export var facade_feature_id: String