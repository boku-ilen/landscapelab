extends Window


@export var position_manager: PositionManager:
	set(new_position_manager):
		position_manager = new_position_manager
		$LayerCompositionUI/LayerCompositionUIConfig.position_manager = position_manager


func _ready():
	close_requested.connect(hide)
