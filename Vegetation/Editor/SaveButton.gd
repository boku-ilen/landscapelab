extends Button


func _ready():
	connect("pressed",Callable(self,"save_override"))


func save_override():
	# Load the paths from the config
	var config = ConfigFile.new()
	config.load("user://vegetation_paths.cfg")
	
	var plant_path = config.get_value("paths", "plant_csv_path")
	var group_path = config.get_value("paths", "group_csv_path")
	
	Vegetation.save_to_files(plant_path, group_path)
