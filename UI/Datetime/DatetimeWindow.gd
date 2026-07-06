extends Window


@export var time_manager: TimeManager:
	set(new_time_manager):
		time_manager = new_time_manager
		$PanelContainer/Datetime.time_manager = time_manager


func _ready():
	close_requested.connect(hide)
	
	if time_manager:
		$PanelContainer/Datetime.time_manager = time_manager
