extends Window


func _ready():
	close_requested.connect(hide)
