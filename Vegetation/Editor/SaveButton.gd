extends Button


func _ready():
	connect("pressed", self, "_on_pressed")


func _on_pressed():
	Vegetation.save_to_files("user://new_plants.csv", "user://new_groups.csv")
