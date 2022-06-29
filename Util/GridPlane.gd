extends Spatial
tool


export var rows: int setget set_rows
export var columns: int setget set_columns


func set_rows(amount: int):
	rows = amount
	for i in range(rows):
		pass


func set_columns(amount: int):
	columns = amount



