extends TableButton

@export var coordinator: DrawingCoordinator

func _ready() -> void:
	pressed.connect(do_capture)
	
func do_capture() -> void:
	coordinator.start_capture()
