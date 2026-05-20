extends TableButton
@export var lab_table: LabTable

func _ready() -> void:
	pressed.connect(lab_table.drawing_coordinator.handle_undo)
