@tool
extends Resource
class_name ModularBuildingMetadata

@export var name := "Building"
@export var building_height: float
@export var roof_height: float
@export var footprint: Array[Vector2] : 
	set(new_footprint):
		footprint = new_footprint
		print("test")
		changed.emit()
@export var height: float = 8.0
@export var position := Vector3.ZERO
@export var floor_definitions: Array[FloorDefinition]
@export var feature_positions: Dictionary[String, Array]
