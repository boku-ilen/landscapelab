extends TableButton
@export var lab_table: LabTable

func _ready():
	# map change TODO
	pressed.connect(lab_table.drawing_coordinator.start_drawing)
	
