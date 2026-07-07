extends Resource
class_name MaterialReplacementPair

enum MaterialReplacementAction {
	CopyAtoB,
	CopyBtoA,
	SwapBoth
}

@export var material_id_a: String
@export var material_id_b: String
@export_range(0,1) var action_probability: float
@export var action_type: MaterialReplacementAction